# linux shell tips

### shebang

```bash
#!/usr/bin/env bash

SCRIPT_DIR=$(dirname "$(readlink -f "$0")")
cd "$SCRIPT_DIR"

```

### if 문에 grep 명령 체크

-   grep을 이용해 도커 네트워크에 특정이름의 네트워크가 존재하는지 체크한다.

```bash
if ! docker network ls | grep -q redis-net; then
    echo 'not exist'
else
    echo 'exist'
fi
```

-   위의 방식은 좋지 않다. 만약 my-redis-net 이라는 네트워크가 존재한다면 오동작하기 때문이다. 다음과 같이 하는 것이 좋다

##### 개선된 버전

```bash
if ! docker network inspect redis-net >/dev/null 2>&1 ; then
    echo "docker network create redis-net"
    docker network create redis-net
fi
```

### 값이 없으면 값을 지정

```bash
 if [ -z "$JBOSS_PIDFILE" ]; then
     JBOSS_PIDFILE=/var/run/wildfly/wildfly.pid
 fi
```

### 파일이 존재하면 실행하는 한줄 스크립트

```bash
[ -r "$JBOSS_CONF" ] && . "${JBOSS_CONF}"
```

### 프로세스가 이미 실행중인지 체크

-   ps 명령에 --pid 옵션을 활용하는 군, 나는 grep을 사용했었는데 ㅠㅠ

```bash
read ppid < $JBOSS_PIDFILE
if [ `ps --pid $ppid 2> /dev/null | grep -c $ppid 2> /dev/null` -eq '1' ]; then
    echo -n "$prog is already running"
fi
```

### 프로세스 종료 시그널 보내고, 종료할때까지 타이머 돌리기

```bash
stop() {
  echo -n $"Stopping $prog: "
  count=0;

  if [ -f $JBOSS_PIDFILE ]; then
    read kpid < $JBOSS_PIDFILE
    let kwait=$SHUTDOWN_WAIT

    # Try issuing SIGTERM
    kill -15 $kpid
    until [ `ps --pid $kpid 2> /dev/null | grep -c $kpid 2> /dev/null` -eq '0' ] || [ $count -gt $kwait ]
    do
      sleep 1
      let count=$count+1;
    done

    if [ $count -gt $kwait ]; then
      kill -9 $kpid
    fi
  fi
  rm -f $JBOSS_PIDFILE
  rm -f $JBOSS_LOCKFILE
  success
  echo
}

```

### case 문

```bash
# 이런 식으로 함수 만들고
status(){
  #...
}

stop() {
  #...
}

case "$1" in
  start)
    start
    ;;
  stop)
    stop
    ;;
  restart)
    $0 stop
    $0 start
    ;;
  status)
    status
    ;;
  *)
    ## If no parameters are given, print which are avaiable.
    echo "Usage: $0 {start|stop|status|restart}"
    exit 1
    ;;
esac
```
