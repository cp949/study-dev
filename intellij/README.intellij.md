# IntelliJ Tips

### 윈도우용

-   붙여넣기 할때 ctrl+v를 사용하는데
    ctrl+shift+v를 하면, ctrl+c 히스토리에서 선택할 수 있다.

### 멀티커서 모드

-   shift+alt+insert를 누르면 멀티커서 모드가 되고
    -   shift 누른채로 화살표 위아래로 이동하면 원하는 위치에 선택된다.
-   ctrl 두번 누르고, ctrl을 누른채로, 화살표 위아래로 하면 여러줄을 선택할 수 있다.



### 빌드 에러

- command line is too long 오류
인텔리J workspace.xml 파일에서 아래 부분 찾아서 추가

```xml
<component name="PropertiesComponent">
    ....
    <property name="dynamic.classpath" value="true" />
</component>

```

### 인텔리J 터미널 한글깨짐
- 보통 터미널을 `C:\Program Files\Git\bin\bash.exe` 을 사용하는데 
`git log` 명령 실행시 한글이 깨지는 문제점이 있다.
- 결론을 미리 말하자면 `-login`  옵션을 추가하면 된다.
- 한글깨짐의 원인은 bash의 환경변수가 LANG=ko_KR.UTF-8으로 설정되지 않아서이다.
환경변수의 확인은 locale 명령으로 확인할 수 있다.
```bash
$ locale
LANG=
LC_CTYPE="C.UTF-8"
LC_NUMERIC="C.UTF-8"
LC_TIME="C.UTF-8"
LC_COLLATE="C.UTF-8"
LC_MONETARY="C.UTF-8"
LC_MESSAGES="C.UTF-8"
LC_ALL=
```

- `bash -login`을 실행하면 홈디렉토리의 .bashrc나 .bash_profile을 처리하므로
환경변수가 제대로 설정된다. 
- `VSCODE`에서는 이 옵션이 기본으로 설정되는 것 같다.
- 인텔리J에서 `ctrl+alt+s`로 터미널 설정을 찾아서
Shell Path를 다음과 같이 변경한다.
```
변경전: C:\Program Files\Git\bin\bash.exe
변경후: "C:\Program Files\Git\bin\bash.exe" -login
```

- 반드시 따옴표를 붙여야 한다.(`"C:\Program Files\Git\bin\bash.exe"`)
- 변경된 터미널을 실행하면 다음과 같이 locale이 변경된 것을 볼 수 있다.
```bash
$ locale
LANG=ko_KR.UTF-8
LC_CTYPE="ko_KR.UTF-8"
LC_NUMERIC="ko_KR.UTF-8"
LC_TIME="ko_KR.UTF-8"
LC_COLLATE="ko_KR.UTF-8"
LC_MONETARY="ko_KR.UTF-8"
LC_MESSAGES="ko_KR.UTF-8"
LC_ALL=
```
- 이제 `git log` 명령의 한글 출력도 정상적으로 확인할 수 있다.


