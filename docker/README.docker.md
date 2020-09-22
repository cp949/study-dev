# install docker-ce

# 기존 설치 제거

```bash
sudo apt-get remove docker docker-engine docker.io
```

# 기본 유틸리티 설치

```bash
sudo apt-get update

sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common \
    bridge-utils
```

### docker repo 추가한 후 docker 설치

```bash
sudo su -

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

apt-get update

apt-get install docker-ce

```

### 도커 전용 사용자 추가

-   사용자의 uid=2000, gid=2000, 홈디렉토리는 /app/work 로 정한다.

```bash
$ sudo groupadd app --gid 2000

$ sudo userapp --gid 2000 -uid 2000 --home-dir /app/work app

# app 사용자로 로그인
$ sudo su - app

# 나만의 스타일로 vim 편집기 설정
$ curl https://raw.githubusercontent.com/cp949/study-linux/master/scripts/setup-vim.sh | bash

# sudoers에 app 사용자 추가
$ sudo vi /etc/sudoers
app ALL=NOPASSWD: ALL

# .bashrc에 입맛에 맞게 적용
$ vi ~/.bashrc
```

### 특정 사용자가 도커를 사용할 수 있게 하기

```bash
sudo usermod -aG docker app
```

### 도커 데이터 저장 위치를 바꾸고 싶다면

-   이미지 등의 저장 위치

```bash
$  cat /etc/docker/daemon.json
```

```json
{
    "data-root": "/home/app/docker-data"
}
```

### docker-compose 설치

visist and check latest version

> current version: 1.25.4
> https://github.com/docker/compose/releases

-   /usr/local/bin에 설치

```bash
curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

chmod +x /usr/local/bin/docker-compose
```

-   또는 \$HOME/.local/bin/ 에 설치할 수도 있다.

```bash
mkdir -p $HOME/.local/bin

curl -L https://github.com/docker/compose/releases/download/1.25.4/docker-compose-`uname -s`-`uname -m` -o $HOME/.local/bin/docker-compose

chmod +x $HOME/.local/bin/docker-compose
```

아래와 같은 리눅스 환경이 있다고 가정

```bash
ip: 192.168.114.31
userId: app
passwd: xxx
```

# 도커 머신 사용하기

### 윈도우에서 리눅스를 도커 호스트로 설정하는 법

-   도커 매뉴얼을 보는게 잘 이해됨

https://docs.docker.com/v17.09/machine/drivers/generic/

-   리눅스에 이미 도커가 설치되어 있지 않다면 설치해준다는데 나는 직접 설치한 후에 했다.(직접 설치하는게 더 나을 것 같기도 하고..)
-   리눅스의 ~/.ssh/authorized_keys에 윈도우의 ssh키를 등록해둔다.

윈도우의 git-bash 터미널에서

```bash
$ docker-machine create \
   --driver generic \
   --generic-ip-address=192.168.114.31 \
   --generic-ssh-key ~/.ssh/id_rsa \
   --generic-ssh-user app  \
   worker31
```

```
Running pre-create checks...
Creating machine...
(worker31) Importing SSH key...
Waiting for machine to be running, this may take a few minutes...
Detecting operating system of created instance...
Waiting for SSH to be available...
Detecting the provisioner...
Provisioning with ubuntu(systemd)...
Installing Docker...
Copying certs to the local machine directory...
Copying certs to the remote machine...
Setting Docker configuration on the remote daemon...
Checking connection to Docker...
Docker is up and running!
To see how to connect your Docker Client to the Docker Engine running on this virtual machine, run: C:\Users\jjfive\.local\bin\docker-machine.exe env worker31
```

git-bash에서 아래 명령을 실행해보면 아래와 같이 나온다.

```bash
$ docker-machine ls

NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER     ERRORS
default    -        virtualbox   Stopped                                       Unknown
worker31   -        generic      Running   tcp://192.168.114.31:2376           v19.03.6
```

### 기본 사용법

```bash
$  docker-machine env worker31
export DOCKER_TLS_VERIFY="1"
export DOCKER_HOST="tcp://192.168.114.31:2376"
export DOCKER_CERT_PATH="C:\Users\jjfive\.docker\machine\machines\worker31"
export DOCKER_MACHINE_NAME="worker31"
export COMPOSE_CONVERT_WINDOWS_PATHS="true"

# 쉘에 적용하려면 eval 명령을 사용
$  eval $(docker-machine env worker31)

$ docker-machine ls

NAME       ACTIVE   DRIVER       STATE     URL                         SWARM   DOCKER     ERRORS
default    -        virtualbox   Stopped                                       Unknown
worker31   *        generic      Running   tcp://192.168.114.31:2376           v19.03.6
```

위의 출력을 보면 worker31에 별표(\*)가 있는 것을 볼 수 있다.
이 상태에서 docker run을 실행하면 worker31 호스트에서 이미지가 실행된다.

```bash
# git-bash 터미널에서 실행
$ docker run hello-world
```

worker31 호스트에서 도커 이미지 목록을 조회하면 hello-world 이미지가 있다.

```bash
# worker31 터미널에서 실행
$  docker images
```

# docker-machine 마운트(실패했음)

### sshfs 사용하기

-   윈도우에 sshfs 설치

```
c:\> choco install -y sshfs
```

-   choco로 설치한 후에 환경변수 PATH에 sshfs를 추가한다.

```bash
$ cd /e/docker-test
$ docker-machine mount worker31:/home/app app
```

마운트 실패함, 다음 기회에 ㅜㅜ

### 도커이미지가 너무 큰 경우

docker history --human --format "{{.CreatedBy}}: {{.Size}}" cas-web-user
