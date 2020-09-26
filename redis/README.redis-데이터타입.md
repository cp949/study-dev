# Redis 데이터 타입

- 아래 URL을 참고하여 정리한다.
- [https://redis.io/topics/data-types-intro](https://redis.io/topics/data-types-intro)

## 데이터 타입

### basic

- Redis는 단순한 키-값 저장소가 아니라 다양한 종류의 값들을 지원하는 데이터 구조 서버이다. 기존의 키-값 저장소는 문자열 키를 문자열 값에 연결하지만, Redis에서는 단순한 문자열로 제한하지 않고, 더 복잡한 데이터 구조를 보유할 수 있다.
- 다음은 Redis에서 지원하는 모든 데이터 구조의 목록이다.
  - Binary-safe 문자열
  - List
  - Set
  - Sorted set
  - Hash
  - Bit array(비트맵)
  - HyperLogLogs
  - Streams

### Redis Key

- Redis 키는 binary-safe이다. 이 말은 어떠한 binary 시퀀스라도 키가 될 수 있음을 뜻한다.
- 예를 들어 "foo"같은 문자열을 키로 사용할 수 있고, JPEG 파일의 내용도 키로 사용할 수 있다. 빈 문자열 또한 유효한 키이다.

#### 키에 관한 몇 가지 규칙

- 매우 긴 키는 좋지 않다. 예를 들어 1024 바이트는 메모리를 많이 차지할 뿐만 아니라, 검색을 위한 키 비교에도 비용이 많이 들기 때문이다.
  - 만약 키로 사용할 값이 너무 길다면, 해싱을 하는 것이 더 나은 방법이다.
- 매우 짧은 키 또한 좋지 않다. "u1000flw"를 키로 사용하는 것보다 "user:1000:followers"를 키로 사용하는 좋다. 더 읽기 좋고, 공간을 조금 더 차지하기는 하지만, 큰 차이는 아니다.
- 스키마를 고수하라. 예를 들어 "object-type:id"는 "user:1000"에서와 같이 좋은 생각이다. 점(.) 또는 대시(-)는 "comment:1234:reply.to" 또는 "comment:1234:reply-to"에서와 같이 여러 단어로 된 필드에 자주 사용된다.
- 키의 최대 크기는 512MB이다.

### Redis Strings

- 가장 간단한 값의 타입은 문자열 타입이다.
- Redis 키는 문자열이므로 문자열과 문자열의 매핑 형태가 된다.
- 문자열 데이터 타입은 많은 경우에 유용하다. HTML 조각이나 페이지의 캐싱같은 곳에 사용할 수 있다.
- redis-cli로 문자열 타입을 테스트해보자.

```py
> set mykey somevalue
OK
> get mykey
"somevalue"
```

- 문자열 값을 꺼내기 위해 위와 같이 `SET`과 `GET`명령을 사용할 수 있다.
- 이미 존재하는 키라면 기존 값을 덮어 씌운다. 기존 키가 문자열 타입이 아니어도 덮어 씌운다.
- 값은 이진 데이터를 포함한 모든 종류의 문자열이 가능하다. 예를 들어 jpeg 이미지도 값으로 저장할 수 있다. 값의 최대 크기는 512MB이다.
- SET 명령은 추가적인 옵션을 지정하여, 동작을 조정할 수 있다.

  - `NX` 옵션은 이미 키가 존재하는 경우 실패한다.
  - `XX` 옵션은 이미 키가 존재하는 경우에만 성공한다.
  - `EX` 옵션은 만료시간을 초단위로 지정한다.
  - `PX` 옵션은 만료시간을 밀리초 단위로 지정한다.

```py
> set mykey "new value1"
OK

# 이미 존재하므로 실패
> set mykey "new value2" NX
(nil)

# 만료 시간 10초
> set mykey "new value3" EX 10
OK
> get mykey
"new value3"

# 10초 후에 접근해보면 nil
> get mykey
(nil)

# NX와 EX를 동시에 사용하는 예
> set mykey2 "new value1" NX EX 10
OK
```

- 문자열이 Redis의 기본값이지만, 재미있는 연산들이 있다.
- `incr`은 atomic increment 연산이다.

```py
> set counter 100
OK
> incr counter
(integer) 101
> get counter
"101"
```

- `incr`은 문자열을 정수로 파싱하고, 1 증가된 값을 새로운 값으로 설정한다.
- `incrby`는 1증가가 아닌, 원하는 크기만큼 증가한다.
- `decr`과 `decrby`는 감소하는 연산이다.
- `incr`이 atomic 하다는 것은 무엇을 의미하는가? 여러 클라이언트가 동시에 같은 키로 INCR 연산을 해도 경쟁 조건에 진입하지 않는다. 예를 들어 클라이언트1이 "10"을 읽고, 동시에 클라이언트2가 "10"을 읽는 경우는 없다. `read-increment-set` 연산은 여러 클라이언트가 동시에 실행되지 않는다.
- 문자열 상의 연산을 위한 다양한 명령들이 존재한다. 예를 들어 GETSET 명령은 새로운 값으로 설정하면서 리턴하는 값은 이전 값이다. 이 명령은 당신의 웹사이트에서 새로운 방문자를 받을때마다 INCR을 사용하여 값을 증가시키는 시스템에서 사용할 수 있다. 당신은 이러한 정보를 Single increment를 잃지 않은채로 한시간에 한번씩 수집하길 원한다고 가정하자. 이때 `GETSET`을 사용하여 새로운 값을 0으로 할당하면서 이전 값을 반환받는다.

- 하나의 명령으로 여러 키에 대해 값을 설정하거나 꺼내는 기능은 지연을 줄이기 위해 유용하다. 이럴 때 사용하는 명령은 `MSET`과 `MGET`이다.
- `MGET` 명령은 값의 배열을 리턴한다.

```py
> mset a 10 b 20 c 30
OK
> mget a b c
1) "10"
2) "20"
3) "30"
```

### 키 공간을 변경하고 조회하기

- 특정 타입으로 정의되지 않은 명령들이 있다. 키의 공간과 상호작용하는데 유용하고, 어떤 타입의 키라도 사용될 수 있다.
- 예를 들어, `EXISTS` 명령은 주어진 키가 존재하면 1, 그렇지 않으면 0을 리턴하다.
- 또 `DEL`은 키와 그와 연관된 값을 지우는 명령인데, 값이 무엇이든지 상관없다.

```py
> set mykey hello
OK
> exists mykey
(integer)1
> del mykey
(integer)1
> exists mykey
(integer)0
```

- `TYPE` 명령은 주어진 키에 저장된 값의 타입을 리턴한다.

- 키 공간과 상호작용하는 많은 명령들이 있는데 `EXISTS`, `DEL`, `TYPE` 3가지가 핵심 명령이다.

```py
> set mykey x
OK
> type mykey
string
> del mykey
(integer) 1
> type mykey
none
```

### exipre: 키의 만료시간

- 더 복잡한 자료구조를 살펴보기 전에, 값의 타입과 상관없는 또 다른 특징인 Redis 만료에 대해 설명할 필요가 있다.
- 기본적으로 어떤 키에 타임아웃을 설정하고, 주어진 시간이 지나면 자동으로 제거된다.
- Redis의 만료에 대한 빠른 정보는 다음과 같다.
  - 초단위 또는 밀리초 단위로 설정할 수 있다.
  - 만료시간 정밀도는 밀리초 단위이다.
  - 만료에 대한 정보는 디스크에 저장된다.

```py
> set key some-value
OK

# 5초후에 만료
> expire key 5
(integer) 1
> get key (immediately)
"some-value"
> get key (after some time)
(nil)
```

- `TTL`은 남은 시간을 체크하는 명령이다.

```py
my-redis:6379> set key hello
OK
my-redis:6379> expire key 5
(integer) 1
my-redis:6379> ttl key
(integer) 3
my-redis:6379> ttl key
(integer) 2
my-redis:6379> ttl key
(integer) 1
my-redis:6379> ttl key
(integer) -2
```

- `TTL`과 `EXPIRE`는 초단위의 명령이고, `PTTL`과 `PEXPIRE`는 밀리초 단위의 명령이다.

### Redis List

- Redis의 List는 링크드 리스트로 구현되었다. 이것은 list에 수백만개의 항목이 있다고 해도, 새로운 요소를 head나 tail에 추가하는 작업은 상수 시간안에 실행된다. 10개가 있던지, 100만개가 있던지 List의 앞이나 뒤에 새로운 요소를 추가할 때의 속도는 동일하다.
- 하지만 Redis의 List는 링크드 리스트로 구현되어 있기 때문에, 인덱스로 List의 요소에 접근하는 것은 빠르지 않다.
- 많은 요소가 있는 컬렉션의 가운데 부분을 빠르게 접근하는 것은 중요하다. 이때는 Sorted Set 자료구조를 사용해야 한다.

### List의 첫번째 단계

- `LPUSH`는 리스트의 앞에 새로운 항목을 추가하고, `RPUSH`는 뒤에 추가한다.
- `LRANGE`는 리스트에서 특정 범위의 요소를 꺼내온다.

```py
> rpush mylist A
(integer) 1
> rpush mylist B
(integer) 2
> lpush mylist first
(integer) 3
> lrange mylist 0 -1
1) "first"
2) "A"
3) "B"
```

- `LRANGE`는 두 개의 인덱스를 지정하는데, 두 인덱스 모두 음수일 수 있다. -1은 마지막 요소, -2는 뒤에서 2번째 항목을 의미한다.
- `RPUSH`는 여러 요소를 하나의 명령으로 추가할 수 있다.

```py
> rpush mylist 1 2 3 4 5 "foo bar"
(integer) 9
> lrange mylist 0 -1
1) "first"
2) "A"
3) "B"
4) "1"
5) "2"
6) "3"
7) "4"
8) "5"
9) "foo bar"
```

- `RPOP`은 끝에서 요소를 하나 꺼내오고 리스트에서는 제거한다.

```py
> rpush mylist a b c
(integer) 3
> rpop mylist
"c"
> rpop mylist
"b"
> rpop mylist
"a"
> rpop mylist
(nil)
```

### Common use cases for lists

- List는 많은 작업에서 유용하다. 두 가지 유용한 시나리오는 다음과 같다.
  - 소셜 네트워크에서 사용자가 마지막으로 작성한 포스트를 기억하기
  - 프로세스간 통신, 생산자-소비자 패턴에서, 생산자가 항목을 리스트에 추가하고, 소비자는 리스트에서 꺼내온다. Redis는 이 시나리오를 위해 신뢰할 수 있는 특별한 명령들을 제공한다.
- 예를 들어, `resque`와 `sidekiq` 루비 라이브러리는 백그라운드 잡을 위해 Redis의 리스트를 사용한다.
- 트위터는 사용자의 마지막 트윗을 Redis List에 넣는다.

### Capped lists(고정된 크기의 리스트)

- 많은 경우 최신의 항목들을 저장하기 위해 List를 사용하길 원한다.
- Redis는 고정된 크기의 컬렉션으로써 리스트를 사용하게 해준다. 항상 최신의 N개의 항목만을 보관하고, LTRIM을 사용하여 오래된 항목은 제거한다.
- `LTRIM`은 지정한 범위를 벗어하는 항목은 제거한다.
- 예제를 보면 쉽게 이해된다.

```py
> rpush mylist 1 2 3 4 5
(integer) 5
> ltrim mylist 0 2
OK
> lrange mylist 0 -1
1) "1"
2) "2"
3) "3"
```

### Blocking operation on lists

- List의 블록킹 연산은 큐를 구현하기에 적합하다.
- 한 프로세스는 List에 항목을 PUSH하고, 다른 프로세스는 작업을 위해 항목을 꺼내오는 생산자/소비자 형태의 프로그램은
  - 생산자는 LPUSH로 항목을 추가하고
  - 소비자는 RPOP으로 값을 꺼내온다.
- 하지만 List가 비어 있다면 RPOP은 NULL을 리턴할 것이고, 소비자는 잠시 쉬었다가, 다시 RPOP을 호출해야 한다. 이러한 방식을 폴링이라고 하는데, 폴링은 좋은 방법이 아니다.
- `RPOP`,`LPOP`에서 값이 없으면 NULL을 리턴하는데 반해, `BRPOP`과 `BLPOP`이라는 명령은 값이 없는 경우 값이 있을때까지 대기하도록 한다. 최대 대기 시간을 지정할 수 있다.
- 아래는 BRPOP 명령의 예제다.

```py
> brpop tasks 5
1) "tasks"
2) "do_something"
```

- 위의 명령은 tasks 리스트에 값이 존재할 때까지 대기하되, 최대 5초동안만 대기하는 예제이다.
- 대기 시간을 0으로 지정하면 계속 대기한다.
- 또한, 동시에 여러 리스트에 대하여 대기할 수도 있다.
- `BRPOP`에 관한 몇 가지 주목해야 할 점은 다음과 같다.
  - 여러 클라이언트가 같은 리스트에 대기하는 경우 먼저 기다린 클라이언트에게 먼저 제공된다.
  - `BRPOP`의 리턴타입은 `RPOP`과는 다르다.`BRPOP`은 여러 List에 대해 대기할 수 있으므로 키이름도 함께 리턴해야 하고, 두 요소의 배열이다.
  - 타임아웃이 되면 NULL을 리턴한다.
- List의 블록킹 연산에 대해 알아야 할 더 많은 것이 있다. 아래의 글을 더 읽어보길 바란다.
  - `RPOPLPUSH`를 이용하여 큐나 회전큐를 더 안전하게 만들 수 있다.
  - `BRPOPLPUSH`라고 부르는 블록킹 변형의 명령도 있다.

### 키의 자동 생성과 제거

- 지금까지의 예제에서 요소를 푸시하기 전에, 빈 List를 만들거나, List가 비었을 때 List를 제거하는 등의 명령은 사용하지 않았다.
- List가 비어 있을때 키를 삭제하거나, 키가 없는 상태에서 요소를 추가하려는 경우 빈 List를 만드는 것은 Redis의 역할이다.
- 이것은 List 뿐만 아니라 Streams, Sets, Sorted Sets, Hash에도 적용된다.
- 기본적으로 이것은 3가지 규칙으로 요약할 수 있다.
  1. 집계 데이터 타입에 요소를 추가할 때 대상 키가 없으면 요소를 추가하기 전에 빈 집계 데이터 타입이 생성된다.
  1. 집계 데이터 타입에서 요소를 제거할 때 값이 비어 있으면 키가 자동으로 삭제된다. Stream 타입은 이 규칙의 유일한 예외이다.
  1. Calling a read-only command such as LLEN (which returns the length of the list), or a write command removing elements, with an empty key, always produces the same result as if the key is holding an empty aggregate type of the type the command expects to find.

- 규칙1의 예제

```py
> del mylist
(integer) 1
> lpush mylist 1 2 3
(integer) 3
```

- 하지만 이미 다른 타입으로 키가 존재하는 경우에는 연산을 실행할 수 없다.
  
```py
> set foo bar
OK
> lpush foo 1 2 3
(error) WRONGTYPE Operation against a key holding the wrong kind of value
> type foo
string
```

- 규칙2의 예제

```py
> lpush mylist 1 2 3
(integer) 3
> exists mylist
(integer) 1
> lpop mylist
"3"
> lpop mylist
"2"
> lpop mylist
"1"

# 요소를 모두 제거했더니, 해당 키가 존재하지 않음
> exists mylist
(integer) 0
```

- 규칙2의 예제

```py
> del mylist
(integer) 0
> llen mylist
(integer) 0
> lpop mylist
(nil)
```

### Redis Hash

```py
> hmset user:1000 username antirez birthyear 1977 verified 1
OK
> hget user:1000 username
"antirez"
> hget user:1000 birthyear
"1977"
> hgetall user:1000
1) "username"
2) "antirez"
3) "birthyear"
4) "1977"
5) "verified"
6) "1"
```

- 해시는 객체를 표현하는 데 편리하지만 실제로 해시 안에 넣을 수있는 필드의 수에는 실제적인 제한 (사용 가능한 메모리 제외)이 없으므로 응용 프로그램 내에서 여러 가지 방법으로 해시를 사용할 수 있습니다.

- HMSET 명령은 해시의 여러 필드를 설정하는 반면 HGET은 단일 필드를 검색합니다. HMGET은 HGET과 유사하지만 값 배열을 반환합니다.

```py
> hmget user:1000 username birthyear no-such-field
1) "antirez"
2) "1977"
3) (nil)
```

- 개별 필드에 대한 연산도 가능하다. ex) `HINCRBY`

```py
> hincrby user:1000 birthyear 10
(integer) 1987
> hincrby user:1000 birthyear 10
(integer) 1997
```

- [해시명령 전체 목록](https://redis.io/commands#hash)을 참고하라
- 몇 개 안되는 요소를 가진 작은 해시가 특별한 방법으로 인코딩되어 메모리 효율적으로 만드는 점은 주목할 만하다.

### Redis Sets

- Set은 순서가 없는 문자열의 집합이다.
- `SADD`는 set에 새 요소를 추가하는 명령이다.
- `SMEMBERS`는 set의 요소들을 조회한다.

```py
> sadd myset 1 2 3
(integer) 3
> smembers myset
1. 3
2. 1
3. 2
```

- `SISMEMBER`는 어떤 값이 포함되어 있는지 조사하는 명령이다.

```py
> sismember myset 3
(integer) 1
> sismember myset 30
(integer) 0
```

- set은 태그 기능을 구현할 때 좋다.
- 아래 예는 뉴스 기사에 태그를 지정하는 것이다. 기사 ID 1000이 태그 1, 2, 5 및 77로 태그 된 경우 세트는 다음 태그 ID를 뉴스 항목과 연결할 수 있습니다.

```py
> sadd news:1000:tags 1 2 5 77
(integer) 4
```

- 모든 태그 목록을 조회하는 것은 다음과 같다.

```py
> smembers news:1000:tags
1. 5
2. 1
3. 77
4. 2
```

- 이 예에서는 태그ID를 태그에 매핑하는 Redis 해시와 같은 다른 데이터 구조가 있다고 가정한다.

- SINTER 명령은 set의 교집합을 구할 수 있다.

```py
> sinter tag:1:news tag:2:news tag:10:news tag:27:news
... results here ...
```

- set에 대해 SPOP명령을 실행하면 랜덤한 한 개의 항목을 제거한다.
- `SUNIONSTORE`는 여러 set의 합집합을 새로운 키에 저장하는 명령이다.

```py
> sadd k1 a b c
(integer) 3

> sadd k2 c d e
(integer) 3

# 혹시 k0키가 있다면 지우고
> del k0

> sunionstore k0 k1 k2
(integer) 3

> smembers k0
1) "c"
2) "b"
3) "e"
4) "a"
5) "d"
```

### Redis Sorted Set

- set 내부의 요소는 스코어와 연결된다. 스코어는 float 타입이다.
- SortedSet에 요소를 추가하는 명령은 `ZADD`이다.
- 두 요소는 스코어 값으로 순서를 비교하며, 스코어값이 같으면 문자열 값으로 비교한다.

```py
> zadd hackers 1940 "Alan Kay"
(integer) 1
> zadd hackers 1957 "Sophie Wilson"
(integer) 1
> zadd hackers 1953 "Richard Stallman"
(integer) 1
> zadd hackers 1949 "Anita Borg"
(integer) 1
```

- `ZADD`는 `SADD`와 비슷하게 요소를 추가하는 명령이며, 위에서 보다시피 `ZADD`는 스코어 인자를 추가해야 한다.
- `SRANGE`에 대응되는 명령은 `ZRANGE`이다.

```py
> zrange hackers 0 -1
1) "Alan Kay"
2) "Anita Borg"
3) "Richard Stallman"
4) "Sophie Wilson"
```

- 역순으로 정렬할 때는 `ZREVRANGE`이다.

```py
> zrevrange hackers 0 -1
1) "Sophie Wilson"
2) "Richard Stallman"
3) "Anita Borg"
4) "Alan Kay"
```

- 스코어값과 함께 조회하는 것도 가능하다. `WITHSCORES` 인자를 지정한다.

```py
> zrange hackers 0 -1 withscores
1) "Alan Kay"
2) "1940"
3) "Anita Borg"
4) "1949"
5) "Richard Stallman"
6) "1953"
7) "Sophie Wilson"
8) "1957"
```

### 범위에서 동작

- `ZRANGEBYSCORE` 명령은 스코어의 범위로 조회한다.

```py
> zrangebyscore hackers -inf 1950
1) "Alan Kay"
2) "Anita Borg"
```

- `ZREMRANGEBYSCORE` 명령은 스코어의 범위로 삭제한다.

```py
# 삭제된 개수를 리턴한다.
> zremrangebyscore hackers 1940 1960
(integer) 4
```

- `ZRANK`는 순위를 리턴한다. `ZREVRANK`는 역순으로 순위를 리턴한다.

```py
> zrank hackers "Anita Borg"
(integer) 4
```

### 사전적인 스코어

- Redis 2.8부터는 사전적인 범위로 값을 가져오는 기능이 추가되었다.
- 주요 명령은 `ZRANGEBYLEX`,`ZREMRANGEBYLEX`,`ZLEXCOUNT`이다. 점수가 모두 같은 경우에만 사용할 수 있다. 점수가 다른 경우의 동작은 규정되지 않았다.
- 예를 들어, 모든 항목에 스코어를 0으로 Sorted Set을 만들어보자.

```py
> zadd hackers 0 "Alan Kay" 0 "Sophie Wilson" 0 "Richard Stallman" 0 "Anita Borg" 0 "Yukihiro Matsumoto" 0 "Hedy Lamarr" 0 "Claude Shannon" 0 "Linus Torvalds" 0 "Alan Turing"
```

- Sorted Set의 정렬 규칙에 의해 이미 사전순으로 정렬된다.

```py
> zrange hackers 0 -1
1) "Alan Kay"
2) "Alan Turing"
3) "Anita Borg"
4) "Claude Shannon"
5) "Hedy Lamarr"
6) "Linus Torvalds"
7) "Richard Stallman"
8) "Sophie Wilson"
9) "Yukihiro Matsumoto"
```

- `ZRANGEBYLEX`명령을 이용해 사전적인 범위로 조회할 수 있다.


> zrangebylex hackers [B [P

```py
1) "Claude Shannon"
2) "Hedy Lamarr"
3) "Linus Torvalds"
```

- 범위는 inclusive 또는 exclusive 하게 지정할 수 있다. `[B` 대신 `(B`로 하면 exclusive 범위를 뜻한다.
- `zrangebylex hackers - [B` 는 B보다 작은 요소를 리턴한다.
- `zrangebylex hackers [B +` 는 B보다 큰 요소를 리턴한다.
- 자세한 내용은 다음 문서를 참고하자.
  - [zrangebylex](https://redis.io/commands/zrangebylex)

### 스코어 업데이트: 리더보드

- Sorted Set의 마지막 설명이다.
- `ZADD`명령을 이미 존재하는 요소의 값에 대해 실행하면 스코어를 업데이트 하는 동작을 한다. 이 동작은 O(log(N)) 복잡도를 가진다. 따라서 Sorted Set은 많은 업데이트가 있을 때 적합하다.(log 시간 함수는 데이터가 많은 경우 더 효율적인 함수)
- 이런 특징을 이용하는 일반적인 사용 시나리오는 리더보드이다. 페이스북 게임은 사용자를 그들의 최고 점수로 정렬하는 기능을 결합한다. 리더보드에서 get-rank 연산에 더하여, 상위 N 사용자를 보여준다.

### Bitmap

- Bitmap은 실제 데이터 타입은 아니고, 문자열 타입상에서 비트 기반의 연산이 정의되어 있다. 문자열은 Binary-safe한 BLOB이고, 최대 512MB이기 때문에,2의 32승 비트를 설정하는 것이 가능하다.
- 비트 연산은 두 그룹으로 분류된다. 
  - 상수시간의 싱글 비트 연산, 가령 비트는 0이나 1로 설정하거나 비트 값을 꺼내오거나
  - 그리고 비트의 그룹에 대한 연산, 예를 들면 주어진 범위에서 비트가 설정된 요소의 개수

- 비트맵의 장점은 공간 절약이 된다는 것이다. 예를 들어 뉴스레터를 받기를 원하는 사용자 40억명을 기억하기 위해 단지 512MB(40억 bit)를 사용할 수 있다.
- `SETBIT`로 비트를 설정하고, `GETBIT`로 값을 꺼내올 수 있다.
  
```py
> setbit key 10 1
(integer) 1
> getbit key 10
(integer) 1
> getbit key 11
(integer) 0
```

- `SETBIT`는 원하는 위치의 비트에 값을 설정한다. 만약 현재 문자열의 길이를 넘어서는 위치에 값을 설정하면, 자동으로 확장시켜준다.
- `GETBIT`는 원하는 위치의 비트의 값을 꺼내온다. 만약 현재 문자열의 길이를 넘어서는 위치의 값을 꺼내려고 시도하면, 0을 리턴한다.

- 비트 그룹과 관련해서는 3개의 명령이 있다.
  1. `BITOP` 두 개의 문자열에 대해 비트 연산을 실행한다(AND,OR,XOR,NOT)  `(=BitOp)`
  1. `BITCOUNT` 1로 설정된 비트의 개수를 리턴한다.
  1. `BITPOS` 0이나 1로 설정된 첫번째 비트를 찾는다.

- `BITPOS`와 `BITCOUNT`는 문자열의 전체 범위가 아닌 특정 바이트 범위로 연산하는 것이 가능하다.

```py
> setbit key 0 1
(integer) 0
> setbit key 100 1
(integer) 0
> bitcount key
(integer) 2
```

### HyperLogLogs

- 뭐하는 건지 모르겠다. 생략

