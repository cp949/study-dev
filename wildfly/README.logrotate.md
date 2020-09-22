# Wildfly LOG 설정

오래된 로그를 어떻게 지울 것인가?
wildfly의 `standalone/log` 폴더에는 아래와 같이 생성된다.

```
server.log
server.log.2020-03-01
server.log.2020-03-02
...
server.log.2020-03-10
```

이런 식으로 로그파일이 만들어지는 이유는 wildfly의 logging 서브시스템에 아래와 같이 `periodic-rotating-file-handler`가 설정되어 있어서 그렇다. 이것이 기본값이다.

```xml
<periodic-rotating-file-handler name="FILE" autoflush="true">
    <formatter>
        <named-formatter name="PATTERN"/>
    </formatter>
    <file relative-to="jboss.server.log.dir" path="server.log"/>
    <suffix value=".yyyy-MM-dd"/>
    <append value="true"/>
</periodic-rotating-file-handler>
```

##### 또 다른 logging 시스템

- `size-rotating-file-handler`는 파일의 크기 기준으로 로그파일을 순환시키는 방식이다.

```xml
<subsystem xmlns="urn:jboss:domain:logging:1.5">
    <size-rotating-file-handler name="FILE" autoflush="true" rotate-on-boot="true">
        ...
        <rotate-size value="400m"/>
        <max-backup-index value="20"/>
        <append value="false"/>
    </size-rotating-file-handler>
    ...
</subsystem>
```

- `periodic-size-rotating-file-handler` 시간과 크기 두 가지 기준을 모두 적용하는 방식이다.

```xml
<periodic-size-rotating-file-handler name="FILE" autoflush="true">
    <formatter>
        <named-formatter name="PATTERN"/>
    </formatter>
    <file relative-to="jboss.server.log.dir" path="server.log"/>
    <suffix value=".yyyy-MM-dd"/>
    <append value="true"/>
    <max-backup-index value="4"/>
    <rotate-size value="10000k"/>
    <encoding value="UTF-8"/>
</periodic-size-rotating-file-handler>
```

이 설정은 적용해보지는 못했는데, 오래된 wildfly라면 안될 수도 있다.(예전 문서에서 이 내용을 찾을 수가 없어서 이렇게 생각중임) 그 경우에는 커스텀하게 작성할 수도 있을 것 같다.

[커스텀 로그 핸들러](https://jbossadventure.wordpress.com/2014/05/06/time-and-size-based-rolling-of-a-log-file-with-eap6as7/)

#### 체크 사항

위 설정 중 기본 값인 `periodic-rotating-file-handler`은 하루에 쌓이는 로그를 `server.log` 파일 한 개에 담아두고, 다음 날이 되면, `suffix`를 붙여서 보관해두는 방식이다. 하루에 한 개씩이라서 관리하기도 좋고 편해보이지만, 이 방식은 로그 파일이 지나치게 커지는 경우를 고려하지 않는 것이 단점이다. 로그 파일 하나가 2GB, 3GB, 300GB 이런식으로 커진다면 좋은 선택은 아니다. 300GB짜리 로그를 열어 볼 수 있는 에디터도 없을 듯..

하지만 로그의 양이 하루에 1GB를 넘지 않는 시스템이 많으므로, 대부분의 시스템에서는 이 방식이 문제 되지 않을 것이다.

#### 로그 시스템에서 요구사항

- 로그 파일을 최대 30일간 유지하고,
- 30개의 백업된 로그파일은 압축된 형태로 보관하면 좋을 것 같다.(디스크 공간 절약)
- 30일보다 오래된 로그파일은 자동으로 삭제되어야 한다.

이를 위해 가장 좋은 방법은 `logrotate`일 것 같다.

#### wildfly와 logrotate 주의사항

- wildfly는 `periodic-rotating-file-handler` 설정에 의해서 자체적으로 하루하루 백업로그를 만든다. \
  `server.log.2020-03-12` 파일은 `2020-03-13` 자정에 만들어진 후 더 이상 변경이 없다.

- 즉, logrotate가 로그를 백업해 줄 필요가 없는 것이다. logrotate는 오래된 로그를 압축하기 위해서 사용한다.

- 그렇기 때문에 인터넷에 있는 대부분의 logrotate 사용법은 wildfly에 적합하지 않다. 예를 들어 30일간 보관하기 위해 `rotate 30`과 `daily` 옵션은 맞지 않다. `rotate 30`은 30번 순환한 후에 31번째 순환 시점에 제일 오래된 로그를 제거하는 방식으로 동작한다. wildfly가 만들어내는 `server.log.2020-03-12`는 여러 번 순환되는 것이 아니라 딱 한번 압축을 위해 순환할 뿐이다. 그래서 logrotate의 설정에는 `daily`와 `rotate 1`로 설정해야 한다.

- 30일 후에 자동으로 지우려면 그래도 `maxage 30`은 필요하지 않나? \
  `maxage 30`을 설정하면, logrotate가 동작할 때 30일 지난 로그 파일을 삭제해 줄 것으로 기대한다. 하지만 `maxage`는 `logrotate가 동작할 때`가 아닌 `순환되는 시점`에 오래되었는지를 체크한다 것에 주의해야 한다. 첫번째 순환되는 시점에는 무조건 오래되지 않았을 것이고, 두 번째 순환시점부터 오래된 것인지 체크하게 된다. 그래서 딱 한번만 순환하는 wildfly에서 `maxage` 옵션은 의미가 없다. 아래 man 페이지를 참고하자. `if the logfile is to be rotated` 부분

```bash
$ man logrotate

maxage count
    Remove rotated logs older than <count> days. The age is only checked if the logfile
    is to be rotated.
```

- `maxage 30`이 없다면 어떻게 오래된 로그를 지울수 있나? \
  logrotate의 `postrotate` 옵션은 logrotate가 실행된 후에 `postrotate`에 적혀있는 명령을 실행한다. 오래된 로그를 삭제하는 명령을 `postrotate`에 적어두면 된다. rotate 할 파일이 하나도 없는 경우, 아래 명령은 실행되지 않는다.

```bash
postrotate
    find /app/root/log/s0101 -name "*.gz" -mtime +30 -delete
endscript
```

`/etc/logrotate.d/` 폴더에 wildfly 파일을 만들어서 아래의 내용을 작성한다.

```
/app/root/log/s0101/server.log.2*
{
	daily
	rotate 1
	missingok
	ifempty
	compress
	sharedscripts
	postrotate
		find /app/root/log/s0101 -name "*.gz" -mtime +30 -delete
	endscript
}

```

- 제일 위에 `/app/root/log/s0101/server.log.2*` 이 부분은 rotate의 대상이 `server.log`가 아니고 `server.log.2020-03-10`과 같은 파일들을 대상으로 하겠다는 설정이다. `server.log`는 wildfly가 로그를 기록하는 중이므로 건드려서는 안된다.
- `rotate`는 순환되는 파일의 개수를 의미한다. 예를 들어 `rotate 5`이고 `daily`가 설정되면 로테이트 된 파일이 5개 넘어가면 삭제한다. 이 말은 로그를 5일간 보관한다는 뜻이다.
- `rotate 1`은 로테이트 된 것을 한 개 유지한다. wildfly 설정에 의해 하루에 한 개씩 로그파일(`ex) server.log.2020-03-12`)이 만들어진다. 이 파일은 한번 순환시켜서 gz로 만든 후에는 더 이상 다시 순환될 일이 없다. 그러므로 `rotate 1`로 설정했다.
- `missingok` 로그파일이 없어도 logrotate 명령의 실행 결과 상태가 에러가 아니라는 설정이다.
- `ifempty` 빈 파일, 즉 0 byte 짜리 파일도 순환 대상이 된다.
- `compress` 압축하겠다는 의미이다. 이 옵션이 설정된 경우, 기본으로 gz 파일로 압축된다.

위의 로그 설정이 `요구사항`을 만족하는지 체크해보자.
로그 폴더에 아래의 파일이 있다고 했을 때

```
server.log
server.log.2020-03-01
server.log.2020-03-02
...
server.log.2020-03-10
```

logrotate를 실행하면

```bash
$  logrotate -f /etc/logrotate.d/wildfly
```

아래와 같이 압축된 형태로 파일이 생성된다.

```
server.log
server.log.2020-03-01.1.gz
server.log.2020-03-02.1.gz
...
server.log.2020-03-10.1.gz
```

이들 파일은 `postrotate`의 `find -mtime +30` 명령에 의해 30일이 지나면 삭제될 것이다.

#### logrotate 대상의 문제점

위의 설정은 그럴 듯 해보이지만 제대로 동작하지 않는다.
logrotate의 대상을 `server.log.2*`로 설정했기 때문에 `server.log.2020-03-01.1.gz` 파일도 대상이 된다. `.gz` 파일은 logrotate에서 제외시켜야 한다.

정규표현식을 사용할 수 있다. `[!.][!g][!z]`

```
/app/root/log/s0101/server.log.2*[!.][!g][!z]
{
        ... 나머지는 동일 ...
}

```

로그 파일은 logrotate에 의해 gz 파일로 압축되고, 위 설정은 확장자가 `.gz`인 파일은 logrotate 대상에서 제외하는 설정이다. [stackoverflow logrotate 정규표현식 참고](https://stackoverflow.com/questions/51816389/how-to-exclude-gz-files-in-logrotate)

#### olddir 옵션을 사용하는 것이 좋다.

gz파일을 제외시키기 위해 정규표현식을 사용할 수도 있지만, gz 파일을 아예 다른 폴더에 넣어 둘 수도 있다. 예를 들면 `archived` 폴더에 오래된 로그를 보관하는 것이 더 나을 것이다.

이를 위해 logrotate의 olddir 설정을 사용한다.

- olddir을 지정하지 않으면 \
  로그 파일과 같은 폴더에 gz 파일이 저장되는데, 압축된 파일이 또 다시 로그의 대상이 되지 않도록 제외시켜야 했다.

이 방식 보다는 압축된 파일을 특정 폴더에 옮겨주는 것이 더 나을 것 같다.

```
/app/root/log/s0101/server.log.2*[!.][!g][!z]
{
        ... 나머지는 동일 ...
        olddir archived
}

```

- 이렇게 하면, gz 파일을 archived 폴더에 옮겨준다.
- `olddir /app/root/log/s0101/archived`라고 설정해도 되는데, logrotate 프로세스의 현재 폴더가 로그 파일이 존재하는 폴더로 설정이 되므로 `olddir archived`라고 했다.

```bash
$  mkdir /app/root/log/s0101/archived
```

#### 완성된 최종 버전의 logrotate 설정은 다음과 같다.

gz 파일을 제외하는 정규표현식과 olddir 설정을 모두 사용했다.

```
/app/root/log/s0101/server.log.2*[!.][!g][!z]
{
	daily
	rotate 1
	missingok
	ifempty
	compress
	olddir archived
	sharedscripts
	postrotate
		find /app/root/log/s0101/archived -name "*.gz" -mtime +30 -delete
	endscript
}

```

몇 줄 안되는 logrotate 설정을 이해하는데 고려해야 할 사항이 많은 것 같다.
