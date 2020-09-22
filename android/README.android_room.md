# 안드로이드 DB

## 안드로이드 테이블 생성 과정

User라는 테이블을 만든다고 가정한다.

### User 엔티티 만들기

```kotlin
@Entity
class User {
  @PrimaryKey val userId: Long ,
  val userName: String
}

// 또는 이런 식으로 키를 자동생성할 수 있다.
@Entity
class User {
  @PrimaryKey(autoGenerate = true)
  @ColumnInfo(name = "user_id")
  val userId: Long = 0,
  val userName: String
}
```

### UserDao 만들기

대략 이런 식으로 만들 수 있다.

```kotlin
abstract class UserDao: EntityDao<User>() {
  @Insert
  abstract suspend fun insert(entity: User): Long

  @Insert
  abstract suspend fun insertAll(entities: List<User>): Long

  @Update
  abstract suspend fun update(entity: User)

  @Delete
  abstract suspend fun deleteEntity(entity:E): Int

  @Transaction
  open suspend fun withTransaction(tx: suspend () -> Unit) = tx()

  suspend fun insertOrUpdate(entity: E): Long {
    return if (entity.id == 0L) {
        insert(entity)
    } else {
        update(entity)
        entity.id
    }
  }

  @Transaction
  open suspend fun insertOrUpdate(entities: List<E>) {
      entities.forEach {
          insertOrUpdate(it)
      }
  }
}
```

### DB 인터페이스 정의

- Database에서 모든 dao를 참조할 수 있도록

```kotlin
interface AppDb {
  fun userDao(): UserDao
}
```

### Room DB 정의

- 앞에서 정의한 DB 인터페이스를 implements 한다

- AppDb는 인터페이스이므로 구현체가 필요한데, Room을 구현체로 사용한다.

```kotlin
@Database(
    version = 1,
    entities = [ User::class ]
)
@TypeConverters(AppDbTypeConverters::class)
abstract class AppRoomDb : RoomDatabase(), AppDb
```

### TypeConverters 정의

- TypeConverter는 아래와 같이 등록한다. enum 타입들은 모두 타입컨버터에 등록해야 한다

```kotlin
object AppDbTypeConverters {
    private val formatter = DateTimeFormatter.ISO_OFFSET_DATE_TIME

    @TypeConverter
    @JvmStatic
    fun toOffsetDateTime(value: String?) = value?.let { formatter.parse(value, OffsetDateTime::from) }


    @TypeConverter
    @JvmStatic
    fun fromOffsetDateTime(date: OffsetDateTime?): String? = date?.format(formatter)


    @TypeConverter
    @JvmStatic
    fun fromUserPlaceType(value: UserPlaceType?) = value?.name

    @TypeConverter
    @JvmStatic
    fun toUserPlaceType(value: String?) = UserPlaceType.values.firstOrNull { it.name == value }

    // ...
}


// 위의 타입컨버터는 UserPlaceType을 문자열로 변환하고 있다
enum class UserPlaceType(val desc: String) {
    HOME("집"),
    OFFICE("회사"),
    ETC("기타");

    companion object {
        val values by lazy { values() }
    }
}
```

### DB의 TransactionRunner 정의

dao의 메소드들을 호출하는 쪽에서 트랜잭션 단위의 실행을 정의하기 위해 TransactionRunner를 정의한다.

```kotlin
interface DbTransactionRunner {
    suspend operator fun <T> invoke(block: suspend () -> T): T
}
```

위의 인터페이스를 Room DB에서 다음과 같이 구현한다.

```kotlin
class AppRoomTransactionRunner @Inject constructor(
    private val db: AppRoomDb
) : DbTransactionRunner {
    override suspend operator fun <T> invoke(block: suspend () -> T): T {
        return db.withTransaction {
            block()
        }
    }
}

```

### 중간 정리

- `User` 테이블 엔티티를 만들고
- `UserDao`를 만들었다.
- 데이터베이스 정의 `AppDb` 인터페이스, UserDao를 참조
- `AppDb`의 구현체 `AppRoomDb`
- 트랜잭션 실행기 `DbTransactionRunner` 인터페이스
- `DbTransactionRunner`의 구현체 `AppRoomTransactionRunner`
- 기타: 타입컨버터 `AppDbTypeConverters`

이제 Dagger에서 이들을 잘 엮어줘야 할 차례다.

### Dagger

크게 세가지 파트다.

- 첫째는 AppRoomDb를 컴포넌트로 정의하고(`Room.databaseBuilder()이용`)
- 그 다음은 각 Dao를 컴포넌트로써 정의하고
- `AppDb`의 인스턴스로는 `AppRoomDb`를 바인드(`@Binds`)하고
- `DbTransactionRunner`의 인스턴스로는 `AppRoomTransactionRunner`를 바인드(`@Binds`)한다.

- AppDb만 Injection하면 Dao는 어디서든 사용할 수 있으니깐 AppDb만 컴포넌트로 만들고, 각 Dao들은 컴포넌트로 만들지 않아도 될 것 같다.

- 하지만 꼭 필요한 Dao만 참조하도록 개발을 하는 것이 올바른 방향이므로 각각의 Dao를 Dagger의 컴포넌트로 등록하여, 이를 사용하는 곳에서는 필요한 Dao만 Injection하는 것이 좋겠다.

##### AppRoomDb의 인스턴스를 컴포넌트로 만들기

```kotlin
@Module
class RoomDbModule {
    @Singleton
    @Provides
    fun provideDatabase(context: Context): AppRoomDb {
        val builder = Room.databaseBuilder(context, AppRoomDb::class.java, "app.db")
            //.addMigrations(*AppRoomDb_Migxxxxx.build())
            .fallbackToDestructiveMigration()
        if (Debug.isDebuggerConnected()) {
            builder.allowMainThreadQueries()
        }
        return builder.build()
    }
}

```

##### AppRoomDb의 각 Dao를 Dagger 컴포넌트로 만들기

```kotlin

@Module
class DbDaoModule {
    @Provides
    fun provideUserDao(db: AppDb) = db.userDao()

    @Provides
    fun provideXXXDao(db: AppDb) = db.xxxDao()

    // ...
}

```

##### 인터페이스와 인스턴스를 바인드

```kotlin
@Module
abstract class DbModuleBinds {
    @Binds
    abstract fun bindAppDb(db: AppRoomDb): AppDb

    @Singleton
    @Binds
    abstract fun provideDbTransactionRunner(runner: AppRoomTransactionRunner): DbTransactionRunner
}

```

##### 모듈 include

- 위에서 각각을 파트별로 `@Module`로 만들었다. 이들 모듈을 `DaggerComponent` include 해서 사용한다.

- 모듈이 3개나 되므로, 복잡하니까 하나로 합친 후에 `DaggerComponent`에서 include하는게 좋겠다.

```kotlin
@Module(
    includes = [
        RoomDbModule::class,
        DbModuleBinds::class,
        DbDaoModule::class
    ]
)
class DbModule
```

이제 DaggerComponent에서 아래와 같이 include하면 된다.

```kotlin
@Singleton
@Component(
    modules = [
        DbModule::class,
        // ...
        RetrofitModule::class
    ]
)
interface AppComponent {
    @Component.Factory
    interface Factory {
        fun create(
            @BindsInstance application: Application,
            @BindsInstance applicationContext: Context
        ): AppComponent
    }
    // ....
}
```

여기까지 진행하면, DB 컴포넌트들을 필요한 곳에 Injection해서 사용할 수 있다.
끝.

## 안드로이드 Room DB의 쿼리

Room을 사용하면서 대단하다고 느낀 점

- 1:n, m:n 조인을 거의 쿼리 없이 만들어준다.
- 데이터의 변경을 observe할 수 있다.

```

```

## 안드로이드 Room을 사용하면서

Room, LiveData, Flow를 함께 사용한다.

- 보통 화면이 나타나면서 데이터를 로드하기 시작한다.
  - Fragment에서 ViewModel에 데이터 로드를 요청하는 방식이 있고
  - Room에서 데이터를 Observe하는 방식이 있다.

Room에서 데이터를 Observe하는 방식은 매우 훌륭하다. 리사이클러뷰에서 주의해야 할 점이 있다.

- 좋아요 기능에서, 좋아요 버튼을 클릭하면 좋아요 버튼을 클릭한 뷰홀더만 상태를 변경해야 한다. 하지만 쿼리의 조회 결과를 목록형태로 Observe하는 것이라서 화면 전체가 깜빡인다. 그리고 성능도 좋지가 않다. 이런 경우는 그냥 필요할때 필요한 만큼만 로드하는 것이 좋다.
  좋아요 버튼을 누르면 다시 로드하지 말고, 그냥 해당 데이터 객체의 값만 바꾸는 것이 더 빠르고 효율적이다.
- 네트워크에서 데이터를 로드하고, DB에 보관하면, Room DB의 옵저버에게 자동으로 이벤트가 보내지고 화면도 함께 갱신된다. 하지만 네트워크에서 데이터 로드가 실패하는 경우 에러의 처리가 다소 복잡하다. Sealed 로 로딩중, 결과데이터, 실패를 알리는 방식을 사용하는데, 아직 익숙하지는 않아서인지 그렇게 매력적으로 보이지는 않는다. try-catch가 더 좋지 않나? Github에 잘 작성된 코드들은 대부분 Sealed로 개발한다. 나도 한번 시도해봐야겠다.
- 리사이클러뷰가 아닌 경우 Room에서 데이터의 변경을 Observing 하는 방식은 대단히 뛰어나다.

## 애플리케이션의 라이프 사이클

- 애플리케이션 시작
- Timber, ThreeTen, Firebase 등 초기화
- 로그인 체크
- 각종 옵저버 등록
  - 로그인이 된 상태에서 자동으로 데이터를 동기화한다든지
  - 푸시토큰을 업데이트 한다든지
