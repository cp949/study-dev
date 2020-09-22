# Pass

pass는 리눅스 사용자 용이다. 윈도우나 git-bash에서는 사용할 수 없다.

https://www.passwordstore.org/

Pass라는 프로그램은 표준 유닉스 비밀번호 매니저이다. 각 비밀번호는 gpg로 암호화된 파일의 내부에 보관된다. 파일명은 웹사이트나 비밀번호를 요구하는 리소스의 제목을 사용한다.

아래는 pass 명령으로 도커 허브의 비밀번호를 저장한 예이다.

```
$  pass
Password Store
└── docker-credential-helpers
    ├── aABCDabcd2ZS5uZXQ=
    │   └── john
    └── docker-pass-initialized-check
```

pass는 각 비밀번호 파일들을 매우 쉽게 관리하도록 해준다. 모든 비밀번호는 `~/.password-store`에 보관되는데, pass는 추가,편집,생성,꺼내오기 등을 할 수 있는 명령들을 제공한다.

### 비밀번호 꺼내기

위와 같이 저장된 상태에서 비밀번호를 꺼내오는 방법은 아래와 같다. 비밀번호를 12345678임을 알 수 있다.

```
$ pass docker-credential-helpers/aABCDabcd2ZS5uZXQ=/john

12345678
```

### 비밀번호 추가

`pass insert` 명령을 통해 비밀번호를 추가할 수 있다.

```bash
$  pass insert Business/hello

$ pass
Password Store
├── Business
│   └── hello
└── docker-credential-helpers
    ├── aABCDabcd2ZS5uZXQ=
    │   └── john
    └── docker-pass-initialized-check
```

### 비밀번호 제거

`pass rm` 명령을 통해 비밀번호를 삭제할 수 있다.

```bash
$  pass rm Business/hello
```

### 설치

-   우분투에는 pass 유틸리티가 기본으로 설치되어 있지는 않다.
    다음과 같이 설치한다.

```bash
$ sudo apt install pass
```

-   설치를 하고 나면, 최초에는 password store가 없다. 이를 위해 `pass init`으로 초기화한다.

```bash
$  pass init
Usage: pass init [--path=subfolder,-p subfolder] gpg-id...
```
