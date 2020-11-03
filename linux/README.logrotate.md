# logrotate

### 설정 파일의 내용

설정 파일의 내용 중 메일 관련 부분은 필요없을 것 같아서 제외했다.

- rotate [숫자] : log파일이 n개 이상 되면 삭제 \
  rotate 4, weekly 인 경우 4주간 보관한다. \
   `ex) rotate 5`
- su user group : 특정 사용자 계정으로 로테이트를 수행한다. \
  `ex) su app app`

- maxage [숫자] : 30일 이상 되면 삭제한다. 백업 파일을 만든 시점을 기준으로 계산된다. 30일동안 logrotate를 실행하지 않아서 원본 로그파일 30일치가 남아 있는 상태에서, 지금 logrotate를 실행했다면, gz 파일들은 현재 시점부터 한달 후에 삭제된다. \
  `ex) maxage 30`

- size : 지정된 용량보다 클 경우 로테이트 실행 \
   `ex) size +100k or size + 100M`
  create [권한][유저] [그룹] : (비어있는)신규 로그 파일을 로테이션 한 직후에 작성한다.
  신규 로그파일의 권한을 지정할 수 있다. \
   `ex) create 644 root root`

- notifempty : 로그 내용이 없으면 로테이트 하지 않음
- ifempty : 로그 내용이 없어도 로테이트 진행
- monthly(월 단위) , weekly(주 단위) , daily(일 단위) 로테이트 진행
- compress : 로테이트 되는 로그파일 gzip 압축
- nocompress : 로테이트 되는 로그파일 gzip 압축 X
- olddir : 오래된 로그를 보관할 폴더, 미리 생성되어 있어야 한다.

- missingok : 로그 파일이 발견되지 않은 경우 에러처리 하지 않음
- dateext : 백업 파일의 이름에 날짜가 들어가도록 함
- copy
  로그 파일의 카피를 생성한다. 이 옵션을 사용하면, 이미 이전 로그 파일이 존재하게 되므로, create 옵션은 무효가 된다.
- copytruncate
  원본 로그파일의 복사본을 만든 후에, 원본 로그 파일은 0 byte로 만든다. \
  이 옵션을 사용하지 않으면 현재 사용중인 로그를 다른 이름으로 move하고 새로운 파일을 생성한다.
- prerotate

```
prerotate
    some command ...
endscript
```

- postrotate

```
postrotate
    some command ...
endscript
```

- `sharedscripts, nosharedscripts`
  각 로그파일이 처리될때마다 `prerotate`, `postrotate`가 실행할 것인가의 여부이다.
- `olddir myarchived` 로그파일을 처리한 결과를 지정된 폴더에 보관한다.

### 예제

내 우분투의 `rsyslog`의 logrotate 설정 파일을 열어봤다.

```bash
$  cat /etc/logrotate.d/rsyslog
```

```text
/var/log/syslog
{
	rotate 7
	daily
	missingok
	notifempty
	delaycompress
	compress
	postrotate
		/usr/lib/rsyslog/rsyslog-rotate
	endscript
}

```
