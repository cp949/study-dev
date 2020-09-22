# 안드로이드 ConstraintLayout

## ConstraintLayout

- layoutParams의 dimemsionRatio를 통해 AspectSize 조정

```kotlin
private fun resizeByAspect(aspectWidth:Int, aspectHeight: Int) {
  val params = imageView.layoutParams as ConstraintLayout.LayoutParams
  params.dimensionRatio = "${aspectWidth}:${aspectHeight}"
}
```
