# Wildfly 서버 설정

### Wildfly 인스턴스

- 실제 운영서버에서는 한 호스트에 두 개의 Wildfly 인스턴스를 띄우는 경우도 있다.

- 개발서버는 그럴 필요가 없지만, 운영환경과 동일한 설정으로 테스트해야 할 경우도 있으므로, 운영서버처럼 두 개의 인스턴스를 띄울 수 있는 구성을 했다.
- 개발서버는 평상시에는 인스턴스 1개로 운영하다가, 필요할 때만 잠깐 2개로 운영할 수 있으면 된다.

- 스크립트 또는 폴더, 파일이름에 s0101 또는 s0102가 포함된 경우가 있는데 `s0101`은 1번 서버의 1번 인스턴스를 의미하고, `s0102`는 1번 서버의 2번 인스턴스를 의미한다.

- 개발서버의 운영은 `s0101`에서만 한다. 그리고 필요할 때만 잠시 `s0102`를 운영할 것이다.

### 폴더 구조의 이해

`standalone` 모드를 기준으로 개발하는 것을 가정한다.

wildfly에서 공식 배포한 docker의 설정에서 기본 디렉토리는 아래와 같다. 컨테이너 내부의 디렉토리이다.

```
/opt/jboss/wildfly/standalone/
/opt/jboss/wildfly/standalone/log
/opt/jboss/wildfly/standalone/deployments
/opt/jboss/wildfly/standalone/configuration
```

### deploy 하기

- war 파일을 배포하기 위해 wildfly 컨테이너의 `/opt/jboss/wildfly/standalone/deployments` 폴더에 war 파일을 복사하면 된다.
- 나는 war 파일이 포함되지 않은 빈 wildfly 도커 이미지를 컨테이너로 띄우고, war 파일은 호스트 OS의 특정 폴더에 복사하면 배포되도록 하고 싶다.
- 이를 위해 deployments 폴더에 대해 도커의 볼륨 매핑을 하면 된다. `docker-compose.yml` 파일에 아래와 같이 볼륨 매핑을 설정했다.

```yaml
volumes:
  - /app/root/data/wildfly/s0101/deployments:/opt/jboss/wildfly/standalone/deployments
```

- 이제 war 파일은 호스트 OS의 `/app/root/data/wildfly/s0101/deployments`에 복사하면 자동으로 배포된다. `wildfly`의 기본 설정에 autodeploy 옵션이 enable 되어 있어서 복사만 하면 자동으로 배포된다. 보통 운영서버에서는 수동으로 deploy를 한다.

##### WAR 파일 업로드

- 개발자 PC에서 war 파일을 업로드 하는 위치는 `/app/NAS/opt/wars/kmac/` 폴더로 결정했다. 개발자는 이 폴더에 war파일을 업로드 한 후 `deployments` 폴더에 복사하면 war 파일이 배포된다. 이를 위해 간단히 스크립트를 작성해두었다.(kmac는 샘플 프로젝트명이다)

- 개발자 PC에서 개발서버로 WAR 파일 업로드하기 위해
  `_build_dev.sh` 파일을 만들었는데, 이 스크립트에서 업로드 부분은 다음과 같다.

```bash
$  scp build/libs/kmac.war app@192.168.x.x:/app/NAS/opt/wars/kmac/kmac.war
```

##### 디플로이

- 업로드 한 후에는, 개발 서버에 접속해서 WAR 파일을 디플로이한다.

```bash
$  cd /app/services/wildfly/scripts/s0101/kmac
$  ./deploy.sh

# 또는 undeploy
$  ./undeploy.sh
```

> `deploy.sh`는 업로드한 war 파일을 `/app/root/data/wildfly/s0101/deployments` 폴더에 복사하는 스크립트다. 별거 없다.

##### `redeploy` 앨리어스 만들기

매번 폴더를 찾아서 deploy 하기는 번거로우니 아래와 같이 alias를 만든다.

```bash
alias redeploy1-kmac='/app/services/wildfly/scripts/s0101/kmac/deploy.sh'
alias redeploy2-kmac='/app/services/wildfly/scripts/s0102/kmac/deploy.sh'
alias redeploy-kmac='redeploy1-kmac'
```

- 이제 아무 폴더에서 `redeploy-kmac`를 실행하면 디플로이 된다.

### 로그 보기

- wildfly 도커 컨테이너는 `/opt/jboss/standalone/log/server.log`에 로그를 남긴다. 그리고 stdout으로도 로그를 남기는데, 이것은 docker log 명령으로 확인할 수 있다.

- 이리 저리 시도해보다가, docker log보다는 특정 파일에 로그를 남기는 것이 더 나을 것 같아서 도커 컨테이너의 `/opt/jboss/standalone/log/server.log`를 호스트 OS의 `/app/root/log/s0101/server.log`에 남도록 볼륨 매핑을 설정하기로 했다.
- 그리고 wildfly의 기본 로그 폴더를 변경하고 싶었다. 경로가 너무 길어서 잘 안외워져서 `/project/logs`에 로그를 남기도록 했다.
- 즉, 도커 컨테이너는 `/project/logs/server.log`에 로그를 남기게 되고, 이 파일은 호스트 OS의 `/app/root/log/s0101/server.log`에서 볼 수 있다.
- `docker-compose.xml` 파일에 아래와 같이 볼륨 매핑을 설정했다.

```yaml
volumes:
  - /app/root/log/s0101:/project/logs
  - ... 다른 매핑은 생략 ...
```

- 호스트 OS의 `instance1.conf`는 `s0101 도커 컨테이너`의 설정이 담겨있는 파일이다. \
  아래와 같이 로그 디렉토리를 설정하고 있다.

```bash
$ cat /app/services/wildfly/instance1.conf
```

```ini
LOG_DIR="/project/logs"
... 생략 ...
```

- 이제 호스트 OS에서 로그를 보려면 아래와 같이 `tail` 명령을 사용할 수 있다.

```bash
$  tail -f /app/root/log/s0101/server.log
```

- 자바 개발자에게 익숙한 jlog 앨리어스를 만들어둔다.

```bash
$  cat ~/.bashrc
alias jlog1='tail -f /app/root/log/s0101/server.log'
alias jlog2='tail -f /app/root/log/s0102/server.log'
alias jlog='jlog1'
```
