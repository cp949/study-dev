# Redis 설치

- 아주 간단하게 redis 서버를 동작시키는 방법이다.
- `docker-compose.yml` 을 아래와 같이 작성하면 된다.

```yml
version: "3"
services:
  redis:
    restart: unless-stopped
    container_name: c-redis
    image: redis:alpine
    command: ['--requirepass "secret"']
    ports:
      - '6379:6379'
    volumes:
      - ./redisdata:/data
```

- 터미널에서 도커 컨테이너를 실행한다. 컨테이너의 이름은 c-redis로 했다.

```bash
$ docker-compose up -d
```

- 쉘로 접속하는 방법은 다음과 같이 하면 된다. bash가 없고 sh만 있다. 
  - 원래 redis:alpine에는 bash가 없는 건가?

```bash
$ docker exec -it c-redis sh
```

- `redis-cli`를 실행하는 것은 다음과 같이 하면 된다.

```bash
$ docker exec -it c-redis redis-cli
```

