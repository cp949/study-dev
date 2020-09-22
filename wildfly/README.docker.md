# Wildfly 서버 설정

## Dockerfile

-   wildfly에서 이렇게 하라고 제공한다. 거기에 내가 원하는 대로 조금 수정했다.
-   (TODO 나중에 원본 스크립트의 링크를 넣어두자)

```dockerfile
FROM jboss/base-jdk:8

ENV DEBIAN_FRONTEND noninteractive

# Set the WILDFLY_VERSION env variable
ENV WILDFLY_VERSION 18.0.1.Final
ENV WILDFLY_SHA1 ef0372589a0f08c36b15360fe7291721a7e3f7d9
ENV JBOSS_HOME /opt/jboss/wildfly

USER root
RUN groupmod -g 2000 jboss && usermod -u 2000 jboss

RUN cd $HOME \
    && curl -O https://download.jboss.org/wildfly/$WILDFLY_VERSION/wildfly-$WILDFLY_VERSION.tar.gz \
    && sha1sum wildfly-$WILDFLY_VERSION.tar.gz | grep $WILDFLY_SHA1 \
    && tar xf wildfly-$WILDFLY_VERSION.tar.gz \
    && mv $HOME/wildfly-$WILDFLY_VERSION $JBOSS_HOME \
    && rm wildfly-$WILDFLY_VERSION.tar.gz \
    && chown -R jboss:0 ${JBOSS_HOME} \
    && chmod -R g+rw ${JBOSS_HOME}


COPY instance.conf /opt/jboss/instance.conf
COPY run-standalone.sh /opt/jboss/run-standalone.sh
RUN chown jboss:jboss -R /opt/jboss && chmod a+x /opt/jboss/run-standalone.sh

# RUN mkdir -p /opt/jboss/wildfly/standalone/log && \
#      ln -sf /dev/null /opt/jboss/wildfly/standalone/log/server.log
# RUN mkdir -p /opt/jboss/wildfly/standalone/log && chown -R jboss.jboss /opt/jboss/wildfly/standalone/log
# VOLUME /opt/jboss/wildfly/standalone/log

# Expose the ports we're interested in
EXPOSE 8080

# Ensure signals are forwarded to the JVM process correctly for graceful shutdown
ENV LAUNCH_JBOSS_IN_BACKGROUND true

USER jboss

# Set the default command to run on boot
# This will boot WildFly in the standalone mode and bind to all interface
# CMD ["/opt/jboss/run-standalone.sh", "-b", "0.0.0.0"]
# CMD ["/opt/jboss/run-standalone.sh"]

```

## docker.compose.yml

```yml
version: '3'
services:
    was1:
        build:
            context: .
        image: was-s0101
        container_name: c-was-s0101
        restart: unless-stopped
        environment:
            MY_INSTANCE_NAME: s0101
        ports:
            - 8001:8080
        volumes:
            - /app/NAS/project/kmac:/NAS
            - /app/root/data/project/kmac/web-admin:/project/web-admin
            - /app/root/log/s0101:/project/logs
            - /app/root/data/wildfly/s0101/deployments:/opt/jboss/wildfly/standalone/deployments
        command: /opt/jboss/run-standalone.sh
        networks:
            - mybridge
networks:
    mybridge:
        external: true
```

## scripts

-   `docker-compose up` 명령을 타이핑 하기 귀찮아서 스크립트를 만들었다.
-   `s0101, s0102` 인스턴스를 띄울 수 있는 설정이다.
-   아직은 좀 부족하다

### 원래 하고자 하는 내용은 이건데

-   `-d`는 `detach` 모드를 의미한다. 백그라운드 데몬으로 실행한다.

```bash
$ docker-compose -f docker-compose.s0101.yml up -d
```

-   `-d`를 제거하면 포그라운드로 동작한다. 스크립트 동작 테스트할 때 요렇게 사용한다.

```bash
$ docker-compose -f docker-compose.s0101.yml up
```

### 실제로 요렇게 작성했다(보완필요)

```bash
instance_name=$1
extra_option=$2
# check clone folder
if [ "$instance_name" == "" ];then
    echo "Usage:"
    echo "$0 <instance_name> [extra-options]"
    echo "example: $0 s0101 "
    echo "         $0 s0101 -it bash"
    echo "         $0 s0101 -d"
    exit 1
fi

instance_config_file="docker-compose.${instance_name}.yml"
if [ ! -e $instance_config_file ]
then
    echo "No such file: $instance_config_file"
    exit 2
fi

mkdir -p /app/root/log/$instance_name
mkdir -p /app/root/data/wildfly/$instance_name

sudo chown app.root -R /app/root/log/$instance_name
sudo chown app.app -R /app/root/data/wildfly/$instance_name

    # -f docker-compose.yml \
    # -d \
instance_name=$instance_name \
  docker-compose \
    -f docker-compose.$instance_name.yml up \
    -d \
    --build $extra_option
```
