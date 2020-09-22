# android

### 몇 가지 링크

- [안드로이드 ORM](https://github.com/MatrixDev/Roomigrant)

- [Navigation Component](https://namjackson.tistory.com/28)

- [이거보고 하트버튼 만들었어](https://medium.com/@rashi.karanpuria/create-beautiful-toggle-buttons-in-android-64d299050dfb)

- [Dagger 한글 강좌](https://www.charlezz.com/?p=1357)

- [chrisbanes의 tivi 프로젝트](https://github.com/chrisbanes/tivi)
- [How to open the bottom sheet directly to full screen?](https://mobikul.com/bottomsheetdialogfragment-with-peekheight-equals-to-screen-height/)

- [Connectivity LiveData](https://blog.stylingandroid.com/connectivity/)

### location

##### 두 점사이의 거리를 계산하는 다양한 방법

https://readyandroid.wordpress.com/calculate-distance-between-two-latlng-points-using-google-api-or-math-function-android/

```java
public static String getDistance(LatLng latlngA, LatLng latlngB) {
    Location locationA = new Location("point A");

    locationA.setLatitude(latlngA.latitude);
    locationA.setLongitude(latlngA.longitude);

    Location locationB = new Location("point B");

    locationB.setLatitude(latlngB.latitude);
    locationB.setLongitude(latlngB.longitude);

    float distance = locationA.distanceTo(locationB)/1000;//To convert Meter in Kilometer
    return String.format("%.2f", distance);
}
```

```java
public static String getDistance(float lat_a, float lng_a, float lat_b, float lng_b) {
    // earth radius is in mile
    double earthRadius = 3958.75;
    double latDiff = Math.toRadians(lat_b - lat_a);
    double lngDiff = Math.toRadians(lng_b - lng_a);
    double a = Math.sin(latDiff / 2) * Math.sin(latDiff / 2)
            + Math.cos(Math.toRadians(lat_a))
            * Math.cos(Math.toRadians(lat_b)) * Math.sin(lngDiff / 2)
            * Math.sin(lngDiff / 2);
    double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    double distance = earthRadius * c;

    int meterConversion = 1609;
    double kmConvertion = 1.6093;
    // return new Float(distance * meterConversion).floatValue();
    return String.format("%.2f", new Float(distance * kmConvertion).floatValue()) + " km";
    // return String.format("%.2f", distance)+" m";
}
```

```java
private double distance(double lat1, double lon1, double lat2, double lon2) {
    double theta = lon1 - lon2;
    double dist = Math.sin(deg2rad(lat1))
                    * Math.sin(deg2rad(lat2))
                    + Math.cos(deg2rad(lat1))
                    * Math.cos(deg2rad(lat2))
                    * Math.cos(deg2rad(theta));
    dist = Math.acos(dist);
    dist = rad2deg(dist);
    dist = dist * 60 * 1.1515;
    return (dist);
}

private double deg2rad(double deg) {
    return (deg * Math.PI / 180.0);
}

private double rad2deg(double rad) {
    return (rad * 180.0 / Math.PI);
}
```

### menu의 showAsAction 의 flags

```xml
<item
    android:id="@+id/action_xxx"
    android:orderInCategory="2"
    android:showAsAction="never"
    android:checkable="true"
    android:title="선택 메뉴"/>
```

- showAsAction의 flag들

```
never : 절대로 액션바에 표시하지 않습니다 (기본값)
ifRoom : 표시할수 있는 공간이 존재하면 표시합니다
withText : 메뉴의 아이콘과 텍스트를 함께 표시합니다
always : 항상 액션바에 표시합니다
```

### 최상위 태스크 확인

아래의 권한은 deprecate되었다. 사용할 수 없는게 아니고, 권한 설정을 안해도 된다.

```xml
<uses-permission android:name="android.permission.GET_TASKS" />
```

getRunningTasks()는 시스템에 어떤 액티비티들이 실행중인지를 조회하는 함수인데, 보안상 문제가 있다. 그래서 자기 자신에 대한 것만 조회되도록 기능이 변경되었고, 따라서 권한 부여가 필요없어진 것 같다.

API 21(Lolipop) 이상 버전부터 ActivityManager의 getRunningTasks() 메서드가 deprecated 되었다

API 23(Mashmallow) 이상 버전부터 getRunningAppProcesses()와 getRunningServices()또한 자신만을 반환하도록 변경되었다

잘 쓰던 AndroidProcesses 라이브러리도 API 25(Naugat) 버전부터 작동하지 않게되었다

UsageStatsManager를 사용하면 Foreground Process들을 가져올 수 있다

시스템 권한을 필요로한다

```java
private String getForegroundPackageName() {
    String packageName = null;
    UsageStatsManager usageStatsManager = (UsageStatsManager)getSystemService(Context.USAGE_STATS_SERVICE);
    final long endTime = System.currentTimeMillis();
    final long beginTime = endTime - 10000;
    final UsageEvents usageEvents = usageStatsManager.queryEvents(beginTime, endTime);
    while (usageEvents.hasNextEvent()) {
        UsageEvents.Event event = new UsageEvents.Event();
        usageEvents.getNextEvent(event);
        if (event.getEventType() == UsageEvents.Event.MOVE_TO_FOREGROUND) {
            packageName = event.getPackageName();
        }
    }
    return packageName;
}
```

# 커스텀 퍼미션 이해

https://developer.android.com/guide/topics/permissions/defining

https://codechacha.com/ko/android-define-custom-permission/

### 노티피케이션 메시지 업데이트 하기

https://stuff.mit.edu/afs/sipb/project/android/docs/training/notify-user/managing.html

### 스프링 애니메이션

https://developer.android.com/guide/topics/graphics/spring-animation

### 유용한 라이브러리

안드로이드 텍스트뷰에 Markdown 적용(웹뷰 없이)
https://github.com/noties/Markwon
