# 윈도우 홈에디션, WSL2에서 도커 사용하기

## 결론: 사용하지 말자

## 아래 내용은 작성하다 말았다. 도커 레지스트리에 push가 안된다

-   그동안 윈도우 홈에디션에서 도커를 사용하기 위해 도커 툴박스를 사용해왔는데 완전한 리눅스 환경이 아니라서 사용하기가 좀 불편하다.
-   윈도우 홈에디션의 WSL2에서 도커를 지원한다고해서 설치해봤다.
-   하지만 WSL2에서는 도커 엔진이 실행되지 않으므로, 윈도우 호스트의 도커 엔진을 연결하는 방법을 사용해야 한다. 그래서 도커 명령을 호출하기 전에 도커 툴박스를 실행해야 한다.
-   개발 서버의 성능이 좋다면, 도커 툴박스의 도커 엔진이 아니라 리눅스 개발 서버의 도커 엔진을 사용할 수도 있다. 이 경우에는 도커 툴박스를 실행할 필요가 없으므로 개발자의 PC를 보다 쾌적하게 사용할 수 있다.

-   Microsoft Store에서 Ubuntu를 찾아서 설치한다. Ubuntu 18.04, Ubuntu 20.04, Ubuntu 이렇게 3가지의 우분투가 있는데, WSL에서 어떤 프로그램은 설치가 잘 안되는 경우도 있어서 가능하면 공식버전을 사용하는 것이 좋다.

Ubuntu를 선택해서 설치했더니 2020년 8월 2일기준 Ubuntu 20.04 버전이 설치되었다.

```
$  lsb_release -a

No LSB modules are available.
Distributor ID: Ubuntu
Description:    Ubuntu 20.04 LTS
Release:        20.04
Codename:       focal
```

### 기존 도커 설치 제거

https://blog.naver.com/PostView.nhn?blogId=ilikebigmac&logNo=222007741507

```bash
$  sudo apt-get remove docker docker-engine docker.io
```

### 필수 유틸리티 추가

```bash
$  sudo apt-get update

$  sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
```

### 도커 GPG 키 등록

도커 이미지를 만든 사람의 퍼블릭키를 신뢰하는 키로 등록하는 과정이다. 신뢰를 해야 리눅스에 도커를 설치를 할 수 있다.

```bash
$  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

#### Trouble shooting

나의 경우는 `apt-key add`에서 아래와 같은 에러가 발생했다.

```
gpg: can't connect to the agent: IPC connect call failed
```

-   gnupg는 2.x 버전인데, software-properties-common을 설치할 때 설치되었다. 기존 설치된 gnupg를 제거하고, gnupg1을 설치한다.

```
$  sudo apt-get remove gpg
$  sudo apt-get install gnupg1
$  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

-   다시 gnupg1을 제거하고, gnupg2를 설치한다. gnupg1은 `apt-key add`를 하기 위해 잠시 설치한 것이다.

```
$  sudo apt-get remove gnupg1

# software-properties-common에 gnupg2가 포함되어 있다.
$  sudo apt-get install software-properties-common
```

### docker-ce 설치

-   도커 리파지토리 추가

```
$  sudo add-apt-repository \
 "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
 $(lsb_release -cs) \
 stable"
```

-   도커 리파지토리 업데이트 후 설치

```
$  sudo apt-get update
$  sudo apt-get install docker-ce
```

### 사용자 추가

사용자를 docker 그룹에 추가한다.

```bash
$  sudo usermod -aG docker $USER
```

### 도커 버전 확인

```
$  docker version
Client: Docker Engine - Community
 Version:           19.03.12
 API version:       1.40
 Go version:        go1.13.10
 Git commit:        48a66213fe
 Built:             Mon Jun 22 15:45:44 2020
 OS/Arch:           linux/amd64
 Experimental:      false
```

## 도커 머신

윈도우 홈에디션 사용자는 도커를 사용하기 위해 도커 툴박스를 설치한다.

-   도커툴박스는 오라클의 버추얼박스로 리눅스를 설치하고, 윈도우와 TCP 연결을 맺어서, 윈도우의 도커 명령을 버추얼박스의 리눅스 상에서 실행하게 해준다.
-   윈도우에서 도커 명령으로 이미지를 만들거나 컨테이너를 실행하면 버추얼박스의 리눅스 상에서 동작한다.

#### 도커 머신을 어떤 목적으로 사용하는가?

-   보통은 제어용 컴퓨터 한대에서 여러 대의 원격 도커 머신에 이미지를 설치하기 위해 사용한다.
-   예를 들면, 개발자 컴퓨터에서 여러 도커 머신(개발 서버)에 이미지를 배포하는 용도로 사용한다.
-   윈도우 홈에디션에서 nodejs 애플리케이션의 도커 이미지를 만드는데 메모리 부족으로 실패한다. 그러면 버추얼박스 리눅스의 메모리를 늘려주면 되는데, 개발자 PC가 16GB인데 그 중의 8GB는 고정으로 할당해야 했다. 즉, 윈도우 메모리의 50%를 도커 이미지를 만들기 위해 고정 할당하는 것이다. (다음에 윈도우를 구매한다면, Pro 버전으로 구매해야 겠다)
-   이런 상황에서는 버추얼박스 리눅스를 도커 머신으로 사용하는 것 보다, 성능 좋은 개발서버를 도커 머신으로 사용하는 것이 나을 것 같다는 생각이 들었다.
-   아래의 내용은 도커 머신을 설치하고 사용하는 방법을 기술한다.

### 도커 머신 설치

아래 링크에 윈도우, 리눅스, 맥에서 각각 설치하는 방법이 나온다.
https://docs.docker.com/machine/install-machine/

WSL 환경이므로 리눅스 설치 방법을 따른다.
2020년 8월2일 현재 최신 버전은 0.16.2

```bash
$  base=https://github.com/docker/machine/releases/download/v0.16.2 &&
  curl -L $base/docker-machine-$(uname -s)-$(uname -m) >/tmp/docker-machine &&
  sudo mv /tmp/docker-machine /usr/local/bin/docker-machine &&
  chmod +x /usr/local/bin/docker-machine
```

### 도커 머신 생성

아래의 IP주소는 개발 서버 IP주소이다. 그리고 개발서버 도커 유저의 authorized_keys에 나의 공개키가 등록되어 있어야 한다.

```bash
$  docker-machine create \
   --driver generic \
   --generic-ip-address=192.168.114.60 \
   --generic-ssh-key ~/.ssh/id_rsa \
   --generic-ssh-user app  \
   server60
```

-   도커머신 확인

아래 명령은 도커 머신의 목록을 확인한다. server60의 ACTIVE가 `-`로 표시되는데, 나의 WSL과 연결되면 `*` 표시로 바뀐다.

```bash
$  docker-machine ls

NAME       ACTIVE   DRIVER    STATE     URL                         SWARM   DOCKER      ERRORS
server60   -        generic   Running   tcp://192.168.114.60:2376           v19.03.12
```

### bash completion 스크립트 설치

```bash
# 아래와 같이 임시 스크립트를 만들고
$  cat a.sh
base=https://raw.githubusercontent.com/docker/machine/v0.16.2
for i in docker-machine-prompt.bash docker-machine-wrapper.bash docker-machine.bash
do
sudo wget "$base/contrib/completion/bash/${i}" -P /etc/bash_completion.d
done

# sudo 실행
$  sudo sh a.sh
```

### docker-machine env 사용법

-   윈도우 WSL과 원격 도커 머신을 연결하는 것은, 환경변수를 설정하는 것이다. 환경변수 설정이 불편하므로 `docker-machine env` 명령을 통해 간편하게 설정할 수 있다.
-   `docker-machine env server60`는 단순히 server60과 연결하기 위한 환경변수를 출력한다.
-   이 환경변수를 WSL의 환경변수로 설정해야 한다. 이를 위해 export 로 시작하는 문장을 긁어서 복사, 붙여넣기 해도 되지만
-   `eval $(docker-machine env server60)`으로 현재 쉘에 환경변수를 직접 적용하는 방법이 편리하다.

```bash
$  docker-machine env server60
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.114.60:2376"
export DOCKER_CERT_PATH="/home/jjfive/.docker/machine/machines/server60"
export DOCKER_MACHINE_NAME="server60"
# Run this command to configure your shell:
# eval $(docker-machine env server60)

# 쉘에 적용하려면 eval 명령을 사용
$  eval $(docker-machine env server60)

$ docker-machine ls

NAME       ACTIVE   DRIVER    STATE     URL                         SWARM   DOCKER      ERRORS
server60   *        generic   Running   tcp://192.168.114.60:2376           v19.03.12
```

-   위의 출력을 보면 server60에 별표(\*)가 있는 것을 볼 수 있다.

-   이 상태에서 docker run을 실행하면 server60 호스트에서 이미지가 실행된다.

```bash
# 윈도우의 WSL에서 실행
$ docker run hello-world
```

server60 호스트에서 도커 이미지 목록을 조회하면 hello-world 이미지가 있다.

```bash
# server60에서 실행
$  docker image ls hello-world

REPOSITORY          TAG                 IMAGE ID
hello-world         latest              bf756fb1ae65

```

## 사설 도커 레지스트리에 업로드

docker 이미지를 만들었으면 이제 사설 도커 레지스트리에 업로드 해야 한다. 아무나 업로드 하면 안되므로, 로그인을 해야 한다.

-   도커 레지스트리로 harbor를 사용하고 있고, harbor 관리자 웹페이지에서 개발자 계정을 등록할 수 있다.

-   사설 도커 레지스트리로 업로드(PUSH) 하기 위해서는 먼저 이미지에 태그를 달아야 한다. 아래와 같이 tag를 달 수 있다. 개발서버에서는 버전번호를 항상 latest로 할 것이라서 버전 번호는 생략했다.

```bash
$  docker tag hello-world hub.jjfive.net/pub/hello-world
```

-   여기까지는 로그인이 필요없다. 도커 레지스트리에 업로드 하려면, 푸시명령을 사용하는데, 그전에 로그인을 해야 한다.
-   하지만 리눅스에서 로그인 하는게 쉽지가 않다.

### 사설 도커 레지스트리에 로그인

아래 명령으로 로그인을 할 수 있다. 하지만 실패한다.

```bash
$  docker login hub.jjfive.net
Username: jjfive
Password:
Error response from daemon: login attempt to https://hub.jjfive.net/v2/ failed with status: 404 Not Found
```

### pass 명령을 이용

-   도커의 로그인은 리눅스의 pass 명령을 이용해야 한다.
-   pass 명령은 리눅스용 비밀번호 관리자이다.
-   pass 명령은 다음과 같이 설치한다.

```
$  sudo apt install pass
```

-   pass는 각 웹사이트나 이메일마다 하나의 파일에 비밀번호를 암호화해서 저장한다.
-   pass로 가 암호화할 때 비대칭키로 암호화하는데, 이를 위해 gpg(gnupg2)가 설치되어 있어야 한다. gnupg2로 나의 개인키/공유키를 만들어야 한다.

#### Gpg2는 동작을 않해

```
$  gpg1 --gen-key

pub   2048R/9F1EB336 2020-08-02
      Key fingerprint = 6FDB E4E5 D763 35D9 8F5A  402A 91DB 58E0 9F1E B336
uid                  jjfive <ohlab.kr@gmail.com>
sub   2048R/5898E1A1 2020-08-02
```

-   키 파일은 `~/.gnupg` 폴더에 생성된다. pass 명령은 이 키파일을 참조한다.
-   위의 gpg1 명령 실행 결과에 pub 부분에 9F1EB336 이 부분이 키의 ID이다. 키의 ID를 `pass init` 명령에 사용한다.

```
$  pass init 9F1EB336

mkdir: created directory '/home/jjfive/.password-store/'
Password store initialized for 9F1EB336
```

### 도커 로그인과 pass 연동

-   도커에 로그인 할 때 pass 명령을 사용하려고 한다.
-   이를 위해 사전에 pass가 사설 도커 레지스트리의 ID와 비밀번호를 저장하고 있어야 하겠다. 다음과 같이 pass에 ID와 비밀번호를 저장하자.

```
$  pass insert docker-credential-helpers/docker-pass-initialized-check
$  docker-credential-pass list

```

# 정말 더러버서 못쓰겠다. 윈도우 Pro를 사던지 해야지
