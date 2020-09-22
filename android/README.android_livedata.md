# 안드로이드 LiveData

## 안드로이드 LiveData의 개발 패턴

개발하다보면 다양한 LiveData를 사용할 수 있다.
내가 실제로 개발하면서 만들어본 것들을 유형별로 정리해본다.

Gps와 관련된 상태는 3가지가 있다는 것을 알았다.

- 첫째 gpsEnabled , GPS가 Enabled되어 있는지
- 둘째 googleApiClient에 연결되었는지 여부
- 셋째 GPS 관련 permission이 부여되었는지 여부

이들 각각을 LiveData로 만들어보겠다.

### GpsEnabledLiveData

Gps가 enabled 되는 것은 Android의 Broadcast로 받을 수 있다.
onActive()상태에서 리시버를 등록하고 onInactive()에서 리시버를 제거하면 된다.

```kotlin
class GpsEnabledLiveData(val context: Context): LiveData<Boolean> {
    override fun onActive() {
        registerReceiver()
        recheckCurrentEnabled()
    }

    override fun onInactive() =  unregisterReceiver()

    private fun recheckCurrentEnabled() {
        postValue(isCurrentEnabled())
    }

    // 이 체크 로직은 Android M이상에서만 가능
    private fun isCurrentEnabled() : Boolean {
        val mgr = context.getSystemService(LocationManager::class.java) ?: return false
        return mgr.isProviderEnabled(LocationManager.GPS_PROVIDER)
    }

    private fun registerReceiver() = context.registerReceiver(
        gpsSwitchStateReceiver,
        IntentFilter(LocationManager.PROVIDERS_CHANGED_ACTION)
    )

    private fun unregisterReceiver() = context.unregisterReceiver(gpsSwitchStateReceiver)

    private val gpsSwitchStateReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) = recheckCurrentEnabled()
    }
}
```

나는 가끔 이런 실수를 한다.

```kotlin
val live = GpsEnabledLiveData(context)
if(live.value == true) {
    println("GPS가 켜져있다")
}
```

이 코드는 LiveData에 observe를 하지 않았으므로 초기값인 null일 것이다.
만약 Gps가 켜져 있는지를 항상 알고자 한다면,
애플리케이션이 시작할때 애플리케이션 레벨로 observe()해야 한다.

보통 Dagger Singleton 컴포넌트로 등록해서 필요한 곳마다 주입받아서 사용한다.

하지만 Gps가 켜져있는지를 구지 애플리케이션 레벨로 관찰할 필요가 없으므로 그렇게 하지는 않겠다.

애플리케이션 레벨로 관찰하기에 적합한 LiveData는 LoginLiveData이다.

##### LoginLiveData

- 필요한 곳에서 주입받아 사용할 수 있다. 싱글톤이므로 한 객체를 공유해야 하고 신규 객체로 직접 생성하는 것은 의미없다.
- `LoginLiveData`는 현재 로그인 상태를 보관하고 있다가, `onActive()`가 되면
  현재값을 전달한다.
- 현재 로그인 상태를 계속 추척해야 하므로, `LoginObserver`를 implements한다.
- Application이 시작할때 관찰을 시작하고, 애플리케이션 종료시점까지 계속 관찰한다. 이를 위해 애플이케이션이 시작할 때 `loginLiveData.observeForever()` 호출하면 된다.

실제로 LoginLiveData를 만들어보니 다양한 이슈들이 있었다. 만들기는 번거로웠지만
사용하는 곳에서는 매우 간단히 사용할 수 있었다.

```kotlin
@Singleton
class LoginLiveData @Inject constructor(
    private val context:Context
): MutableLiveData<Boolean>(), LoginObserver {

    val isLoggedIn: Boolean get() = this.value == true
    val isNotLoggedIn: Boolean get() = !isLoggedIn

    fun onLogin() {  postValue(true)  }
    fun onLogout() {  postValue(false) }

    override fun onActive() {
        // empty, 할일 없다
    }

    override fun onInactive() {
        // empty, 할일 없다
    }
}
```

LoginLiveData 자체는 정말 심플하다. 로그인 여부를 Boolean 값으로 가지고 있을 뿐이다.

여기서는 내용을 생략하지만, 두 가지 알아야 할 점이 있다.

- LoginLiveData의 초기값은 null이므로 현재의 로그인 상태를 애플리케이션 시작시점에 설정해야 한다.
- 로그인 상태가 변경되었을때 상태를 전달받아 자신의 상태를 갱신해야 한다. 그러기 위해서 LoginObserver를 implements하고 있다.(LoginObserver는 직접 만든 것이므로 생략)

- 이렇게, 다소 번거로운 작업을 해야 하지만, login 상태변화를 알고자 하는 다른 곳에서는
  LoginLiveData만 observe하면 되므로 굉장히 간단해진다.

```kotlin

```
