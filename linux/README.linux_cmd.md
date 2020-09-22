# linux command

내가 몰랐던 명령어들 정리한다.

### fuser

fuser 명령은 특정 파일을 어떤 프로세스에서 사용중인지 확인할 때 사용한다.

```bash
$  fuser server.log
/home/jjfive/log/server.log: 20066
```

ps 명령으로 확인해보면 다음과 같다.

```bash
$  ps -q 20066
  PID TTY          TIME CMD
20066 ?        00:03:16 java
```

fuser 명령은 단순히 pid를 확인하는 것 외에도, 특정 파일을 사용하는 프로세스에 시그널을 보낼 수도 있고(-k 옵션), 별도의 추가 명령 없이, 사용중인 프로세스의 사용자ID를 확인할 수도 있다.
`man fuser`로 자세한 명령을 확인하면 될 듯.

### lsof

### pgrep
