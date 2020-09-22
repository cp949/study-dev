# Android View layout pass

### View의 layout 변경관련

https://cheesecakelabs.com/blog/understanding-android-views-dimensions-set/

OnLayoutChangeListener
view의 bounds가 변경되었을때 호출된다.

각 뷰는 두가지 종류의 크기가 있다.
measured width/height => 얼마만큼의 크기를 원하는가, 레이아웃된 후의 실제크기
원하는 크기가 항상 제공받을 수는 없다. 예를 들어 부모의 크기보다 큰 것을 원하는 경우이다.

측정된 크기와 실제 크기는 두 단계를 거쳐서 설정된다.

- Measure pass:

  > 각 뷰는 원하는 크기가 있다. measured dimension은 뷰가 원하는 크기이다.
  > measure pass는 루트뷰그룹에서 시작되어 탑다운형태로 부모에서 자식으로 설정된다.
  > 각 뷰는 자기의 자식이 원하는 dimension을 리턴한다. 단계가 끝이나면
  > 모든 뷰는 measured width와 height가 설정된다.

- Layout pass:
  > 각 부모는 실제 크기내에서 자신의 자식의 위치를 배치할 책임을 갖는다.
  > Measure pass에서 설정된 크기가 설정되지 않을 수도 있다.

Layout pass가 끝이나면, OS에 의해서 그려지기 시작한다.
아래는 LinearLayout에 TextView를 넣고, onMeasure와 onLayout이 호출되는 과정을 보여준다.

```
1 onCreate() executed
2 onStart() executed
3 onResume() executed
4 LinearLayout: entering onMeasure(). Measured width: 0
5 TextView: entering onMeasure(). Measured width: 0
6 TextView: leaving onMeasure(). Measured width: 171
7 LinearLayout: leaving onMeasure(). Measured width: 171
8 LinearLayout: entering onLayout(). Actual width: 171
9 TextView: entering layout(). Actual width: 0
10 TextView: leaving layout(). Actual width: 171
11 LinearLayout: leaving onLayout(). Actual width: 171
12 onWindowFocusChanged() executed
13 LinearLayout: entering onMeasure(). Measured width: 171
14 TextView: entering onMeasure(). Measured width: 171
15 TextView: leaving onMeasure(). Measured width: 171
16 LinearLayout: leaving onMeasure(). Measured width: 171
17 LinearLayout: entering onLayout(). Actual width: 171
18 TextView: entering layout(). Actual width: 171
19 TextView: leaving layout(). Actual width: 171
20 LinearLayout: leaving onLayout(). Actual width: 171
21 TextView: draw() executed
```

위의 로그를 보면
Measure/Layout Pass가 두번 일어나는 것을 볼 수 있다.
onWindowFocusChanged() 전에 한번, 후에 한번
그리고 TextView는 onWindowFocusChanged() 후에 draw()가 호출된다.

View.post(Runnable) ui가 layout된 후에 호출된다.

- ViewTreeObserver.OnGlobalLayoutListener

> 뷰 트리에서 글로벌 레이아웃이 변할때 실행된다.
> 뷰의 트리상의 어떤 뷰라도 레이아웃이 변하면 호출된다.
> 리스너가 처음 호출될때 제거하는 방식으로 사용되는데, 그것은 관심이 있는 뷰가 레이아웃되었음을 보장해주지는 않는다.
> 그래서 width와 height가 설정되지 않은 상태일 수도 있다.

- View.OnLayoutChangeListener
  > 레이아웃의 바운드가 변경되어서, 레이아웃이 처리되어야 할때 호출된다.
  > 이것은 약속처럼 보인다.이것은 뷰트리 전체에 대한 것이 아닌, 특정 뷰가 변경되었을때 트리거 된다.
  > 만약 이 리스너를 추가했을때 이미 레이아웃되었다면, 콜백은 실행되지 않는다.
  > 이 경우에는 당신은 직접 호출해야 할 것이다.

##### Android KTX

뷰가 레이아웃되었을때 호출되는 콜백으로 View.doOnLayout() 확장이 있다. 그리고 이것은 뷰가 이미 레이아웃되었어도 호출해주는 것을 보장한다.
