# WILDFLY 서버 설정

- [ Wildfly 기본 설정 ](README.settings.md)
- [ Wildfly logrotate ](README.logrotate.md)
- [ Wildfly docker ](README.docker.md)

# TODO

### wildfly와 도커에 대한 고민

- 도커에 wildfly 컨테이너를 띄울때, war 파일이 포함된 이미지를 만드는 것이 바람직한 사용법이다. 그래야 컨테이너를 여러 개 띄우기가 좋고, 시스템 독립적으로 도커를 사용하게 된다.
- 하지만 각 컨테이너마다 설정이 달라야 한다면 그것은 같은 이미지가 아닌 것이다.
  여러 컨테이너들이 누가 누구인지를 식별해야 하기 위해, 컨테이너마다 ID를 부여해야 하는데, 이를 위해 환경변수에 컨테이너의 ID를 부여했다. 각 컨테이너마다 다른 환경변수를 설정해야 하므로, 같은 이미지를 사용할 수가 없었다.
- 그래서 거의 비슷한 docker-compose.xml을 각 인스턴스별로 만들어야 했다. 더 좋은 아이디어가 필요하다.
