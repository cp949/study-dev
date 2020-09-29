# Mongo DB

## Docker 환경에서 설치하기

- `docker-compose.xml`을 다음과 같이 작성한다.

```text
version: "3"
services:
  mongo:
    restart: unless-stopped
    container_name: c-mongo
    image: mongo:4.4
    ports:
      - 27017:27017
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: secret
      MONGO_INITDB_DATABASE: sample
      MONGO_USERNAME: sample
      MONGO_PASSWORD: 1234
    volumes:
      - ./dbdata:/data/db
      - ./mongo-init.sh:/docker-entrypoint-initdb.d/mongo-init.sh:ro
```

- 위의 mongo-init.sh는 다음과 같이 작성한다.
- 문서를 보니까 `*.js` 를 넣도록 하던데, 쉘 스크립트를 넣어도 되는 것 같다.
  - [https://hub.docker.com/_/mongo](https://hub.docker.com/_/mongo)

```bash
mongo -- "$MONGO_INITDB_DATABASE" <<EOF
db.createUser({
    user: "$MONGO_USERNAME",
    pwd: "$MONGO_PASSWORD",
    roles: [
        { role: 'readWrite', db:"$MONGO_INITDB_DATABASE" }
    ]
})
EOF
```

- 데이터베이스 설정을 하지 않아도 기본으로 동작하지만,
- 설정을 하려면 이미지에서 설정파일을 복사해서 편집하면 된다.
- 백그라운드로 몽고서버를 시작한다.

```bash
$ docker-compose up -d
```

- 도커 컨테이너에 bash로 접속

```bash
$ docker exec -it c-mongo bash
```

- DB 쉘을 실행한다.

```bash
$ root@a786f144de6d: mongo

MongoDB shell version v4.4.1
connecting to: mongodb://127.0.0.1:27017/?compressors=disabled&gssapiServiceName=mongodb
Implicit session: session { "id" : UUID("f0b046c5-b5da-4c06-93b2-6f1cb95ccebf") }
MongoDB server version: 4.4.1
Welcome to the MongoDB shell.

```

```mongo
> use sample
switched to db sample
db.createUser({
    user:"sample",
    pwd:"1234",
    roles: [ { role: "readWrite", db: "sample" }]
})

# 빠져나오고
> exit
```

- admin 데이터베이스에 admin으로 접속해본다.

```bash
$ mongo -u sample -p '1234' -authenticationDatabase sample
```

## Admin tools for Windows

- 윈도우 환경에서 원격으로 접속할 때는 `Robomongo`를 사용할 수 있다.
  - 다른 도구가 더 있는지는 아직 조사해보지 않았는데, 일단 `Robomongo`로 만족하고 있다.
- 윈도우에서 `choco`를 사용하여 간편하게 설치할 수 있다.

```sh
choco install -y robo3t
```
