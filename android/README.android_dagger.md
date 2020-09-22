# 안드로이드 Dagger

한 프로젝트를 여러 모듈로 분리해서 개발을 하는 이유가 있을까?

예를 들면 이런 식으로

- 데이터 모듈
- UI 모듈
- 공통 라이브러리
- 메인 애플리케이션

번거롭기만 하지 않을까? 나는 안드로이드를 개발하면서

#### 메인 애플리케이션과 공통 라이브러리

모든 앱에서 공통으로 사용할 부분을 따로 뽑아서 모듈로 만들어두고,
모든 프로젝트에서 라이브러리로써 사용해왔다. 자주 사용할 유틸리티들과 몇가지 UI들을 모아둔 것이다.
한 몇년간 잘 사용했다.

```
:app
:common-lib
```

그리고 이렇게 개발하는게 별 다른 불편함은 느끼지 못했다.

Dagger도 사용하고, RxJava, coroutine, LiveData, ViewModel 등 구글의 최신 트렌드를 모두 따라가면서 이렇게 개발했다.

#### 메인 애플리케이션과 공통 라이브러리

이번 프로젝트는 이렇게 개발해보고 있다.

```
:app
:android-base
:android-data
:android-ui
:common-ui
```

이렇게 분리하는게 크게 매력적이라는 것까지는 모르겠다.

다만, `:android-data` 모듈은 매우 만족한다.

`:android-data`는 `Retrofit`으로 네트워크에 접근하고, Android Room DB에 저장하는 기능만을 가지고 있다. 그리고 Repo를 통해 데이터의 저장과 조회를 추상화했다.

Repo가 아주 좋다. 다른 컴포넌트들은 Repo만 참조한다. 네트워크로 조회하든, DB에서 조회하든 몰라도 된다. 메소드의 정의가 `suspend`라서 어차피 시간이 걸릴 수 있음을 가정하고 개발하는 것이다.

이렇게 했더니, 코드가 많이 개선되는 것을 느꼈다. 다른 모듈에 노출하고 싶은 부분만 인터페이스로 추상화하는 코드가 더 늘어났지만, 이것은 바람직한 개발방향이다.

뷰모델은 뷰와 데이터를 중재하는 로직만 신경쓰면 된다. 데이터의 저장소가 Room이든 파일이든, 또는 Retrofit이든 신경을 쓰지 않아도 된다.

원래 신경을 안쓰도록 개발하긴 했는데, 뭐랄까.. 같은 모듈에 없으니 더 신경이 안쓰이는 느낌이다. ^^;

이런 작업들은 코루틴과 LiveData가 없었다면 불가능했을 것이다.

그리고 또 하나, 그동안 너무 기본적인 것만 사용해왔던, 그래서 모르는게 아직도 많은 Dagger이다. 한 프로젝트를 여러개의 모듈로 분리하면서 Dagger의 강력함을 더욱 느끼고, 적극적으로 적용하고 있다.

이제 나의 공부 주제에 Dagger가 포함되었다.

## Dagger

Dagger는 내가 모르는 부분을 위주로 기록해두겠다.

- Dagger의 한글 문서
  https://www.charlezz.com/?p=1357

- Service에 Inject하는 방법 찾다가 이 문서도 보게 되었다.
  https://medium.com/tompee/dagger-for-android-a-detailed-guide-b7df2f40c044

### DaggerComponent

그동안 `dagger-android`는 사용하지 않았다. 그래서 `AppComponent`는 아래와 같이 생성한다.

```kotlin
class ApplicationLoader : Application() {
    override val component: AppComponent by lazy {
        DaggerAppComponent.factory().create(this, applicationContext)
    }
}

@Singleton
@Component(
    modules = [
        AppAssistedModule::class,
        AppModule::class,
        // ...
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
    // ...
}

```

`Activity`에서는 뷰모델만 있으면 되기 때문에 구지 `AndroidInjector` 같은 게 필요하지 않았다. 그런데 `Service`에서 `@Inject`하려고 보니 필요해졌다.

그래서 이제는 `dagger-android`를 사용한다. 아래와 같이 바뀌었다.

`ApplicationLoader`는 `DaggerApplication`을 상속받는다. 코드를 보니 `DaggerApplication`은 `onCreate()`에서 androidInjector를 `inject`한다.

`AppComponent`는 `AndroidInjector<ApplicationLoader>`를 상속받는다.

```kotlin

class ApplicationLoader : DaggerApplication(), DaggerComponentProvider {
    companion object {
        lateinit var shared: ApplicationLoader private set
    }

    override fun applicationInjector(): AndroidInjector<out DaggerApplication> {
        return component
    }

    override val component: AppComponent by lazy {
        DaggerAppComponent.factory().create(this, applicationContext)
    }

    override fun onCreate() {
        super.onCreate()
        // ...
    }
    // ...
}

@Singleton
@Component(
    modules = [
        AndroidInjectionModule::class,
        AppAssistedModule::class,
        AppModule::class,
        // ...
    ]
)
interface AppComponent : AndroidInjector<ApplicationLoader> {
    @Component.Factory
    interface Factory {
        fun create(
            @BindsInstance application: Application,
            @BindsInstance applicationContext: Context
        ): AppComponent
    }
    // ...
}

```

AppComponent의 `modules`에 `AndroidInjectionModule::class`부분이 추가되었다. 그리고 AppComponent는 `AndroidInjector<ApplicationLoader>`를 상속받는다.

이 정도 차이만 있고, 기존의 사용법과 다르지 않다. 그냥 똑같다.

#### Service에서 Inject

Service는 OS가 생성하는 것이라서 Dagger가 생성할 수 없다. 따라서 Service의 `onCreate()`부분에 `Inject`하는 로직을 추가해야 한다.

`dagger-android`를 사용하지 않도고 `inject`하는 방법이 있긴 하던데, 다소 복잡하다. 그래서 `dagger-android`를 사용하기 시작했다.

나는 지금 Geofence를 개발하고 있는데, Geofence Enter가 브로드캐스트로 날라오면, JobIntentService를 실행하는 방식이다.

브로드캐스트 리시버는 구지 볼 필요는 없지만 몇 줄 안되니 그냥 포함한다.

```kotlin
// Android Manifest
<receiver android:name=".GeofenceBroadcastReceiver" />

class GeofenceBroadcastReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context?, intent: Intent?) {
        GeofenceJobService.enqueueWork(context, intent)
    }
}
```

JobIntentService 코드는 아래와 같다.

onCreate()의 첫번째 줄에 `AndroidInjection.inject(this)`를 하는 것이 보인다.

```kotlin
class GeofenceJobService : JobIntentService() {

    @Inject
    lateinit var notificationController: NotificationController

    override fun onCreate() {
        AndroidInjection.inject(this)
        super.onCreate()
    }

    override fun onHandleWork(intent: Intent) {
        // ...
    }
}
```

위와 같이 Injection이 되도록 Dagger를 설정해 보자.

방법이 `@Subcomponent`를 사용하는 방식과 `@ContributesAndroidInjector`을 사용하는 방식이 있는데, 나는 일단 `@Subcomponent`를 사용해서 만들었다.

```kotlin
@Subcomponent
interface GeofenceJobServiceSubcomponent : AndroidInjector<GeofenceJobService> {
    @Subcomponent.Factory
    interface Factory : AndroidInjector.Factory<GeofenceJobService>
}


@Module(subcomponents = [GeofenceJobServiceSubcomponent::class])
abstract class GeofenceJobServiceModule {

    @Binds
    @IntoMap
    @ClassKey(GeofenceJobService::class)
    abstract fun bindAndroidInjector(factory: GeofenceJobServiceSubcomponent.Factory): AndroidInjector.Factory<*>
}

```

그리고 애플리케이션 컴포넌트에 위의 모듈을 추가한다.

```kotlin
@Singleton
@Component(
    modules = [
        //...
        GeofenceJobServiceModule::class
    ]
)
interface AppComponent : AndroidInjector<ApplicationLoader> {
```

되었다. 이렇게 하면 된다. Geofence도 잘 되고 Service에서 Injection도 잘 된다.

#### GeofenceJobService에서 하려고 하는 것

- `GeofenceJobService`는 어떤 위치에 진입했음을 알려주는 것이다.

- 서비스의 인텐트에는 위도,경도와, 이 위치에서 Trigger된 Geofence 목록이 포함되어 있다.

- Geofence의 requestId는 `alio-{alioId}`포맷이므로,

- Alio 테이블에서 해당 alio를 조회하고,
- 현재 날씨와 매칭이 되는지 파악한다.
  현재 날씨가 없다면 서버에서 날씨를 조회해야 한다.

- 매칭을 조사해서 일치하면 Notification을 표시한다.

- 대상이 본인이 아니라면 서버에 Notification을 표시하도록 요청해야 한다.
