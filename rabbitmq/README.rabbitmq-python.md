# RabbitMQ

메시지큐들이 너무 많아서 뭐를 써야 할지 모르겠다.

- HA 구성이 가능하고 도커 친화적인 메시지큐를 찾다가 RabbitMQ를 사용해보기로 했다.
- RabbitMQ는 다양한 언어별로 예제와 문서가 잘 되어 있다.
- 파이썬 문서가 간결해서 학습하기에 편하다.
- 먼저 파이썬 문서로 용어나 개념을 익히고 자바로 익히는 것이 좋을 것 같다.

## RabbitMQ의 설치

- RabbitMQ는 erlang으로 만들어져서 erlang도 함께 설치해야 한다. apt-get으로 RabbitMQ를 설치하면 필요한 라이브러리들이 자동으로 함께 설치된다. 그런데 함께 설치되는 것들이 너무 많다.
- 그래서 Docker가 좋다. 설치와 제거가 간편해서 연습용으로 사용해 보기에 좋다.
- 2020년 7월 최신 버전은 RabbitMQ 3.8.5, Erlang 23.0.2 이다.

### Docker로 설치

Dockerfile은 아래와 같이 만든다. 처음에는 안만들어도 상관없지만, 어차피 나중에 만들 것이라서 함께 만든다.

```docker
# Dockerfile

FROM rabbitmq:3-management

EXPOSE 5672 15672

```

아래와 같이 이미지 이름을 my-rabbitmq로 하여 도커 이미지를 만든다.

```bash
## 이미지 만들기
$  docker build -t my-rabbitmq .

## 이미지 만들어졌는지 확인
$  docker image ls
```

이제 아래와 같은 docker-compose.xml 파일을 만든다. 컨테이너 이름은 c-my-rabbitmq로 했다.

```yml
# docker-compose.xml

version: '3'
services:
    my-rabbitmq:
        image: my-rabbitmq
        container_name: c-my-rabbitmq
        ports:
            - 5672:5672
            - 15672:15672
        restart: unless-stopped
        environment:
            RABBITMQ_DEFAULT_USER: admin
            RABBITMQ_DEFAULT_PASS: 1111
```

아래의 명령을 실행하면 컨테이너가 실행된다.

```bash
# 포그라운드로 도커 컨테이너 실행
$  docker-compose up --build

# 백그라운드로 도커 컨테이너 실행할 때는 -d(detach) 옵션 추가
$  docker-compose up -d --build
```

여기까지가 설치의 끝이다.

## RabbitMQ의 설정

RabbitMQ를 설정하려면 RabbitMQ를 이해해야 한다. 그 중에 연결을 위해 반드시 필요한 포트번호에 대해서만 일단 적는다.

### 포트번호

- 포트번호 15672, RabbitMQ는 관리자 웹페이지를 제공하는데 웹페이지의 기본 포트번호가 15672번이다.

- 포트번호 5672, RabbitMQ 클라이언트가 메시지큐와 통신할 포트번호다.

- 61613은 STOMP용 포트번호다. RabbitMQ STOMP 플러그인을 설치하면 사용할 수 있다.

- 전체 포트번호 설명은 아래 링크에 있다.
    https://www.rabbitmq.com/networking.html#ports

### RabbitMQ 관리자 페이지 접속

브라우저에서 아래의 URL에 접속한다.

```sh
ID/PW는 admin/1111

http://localhost:15672/
```

### RabbitMQ Client 프로그램 작성

파이썬으로 RabbitMQ Client 프로그램을 작성하려면 파이썬용 RabbitMQ 라이브러리가 필요하다. 여기서는 pika를 사용한다. RabbitMQ 팀에서 추천하는 파이썬 라이브러리가 pika이다.

#### pika 설치

```bash
$  pip install pika
```

#### RabbitMQ에 메시지 보내기

아직 작성하지는 말고 그냥 눈으로 코드를 살펴보자. 연결을 하고 메시지를 보내는 샘플코드이다.

```python
import pika

params = pika.URLParameters("amqp://admin:1111@localhost:5672/")
connection = pika.BlockingConnection(params)
channel = connection.channel()

channel.basic_publish(exchange='cafe.topic',
                      routing_key='order.coffee.1',
                      body=b'hello world')
connection.close()

```

# RabbitMQ 튜토리얼

이제 대충 겉모양은 확인하였고 단계별로 테스트해보자.

아래의 RabbitMQ의 공식문서를 내 나름으로 정리해본다.

https://www.rabbitmq.com/getstarted.html

## 튜토리얼1 Hello world

RabbitMQ는 메시지를 받아서 전달하는 메시지 브로커다. 이것은 우체국처럼 생각할 수 있다. 누군가 우체국에 편지를 보내면, 그 편지가 수신자에게 도착한다. RabbitMQ는 우편함이자, 우체국이고, 배달원으로 생각할 수 있다.

- 메시지를 보내는 프로그램은 생산자(Producer)이다.
- 소비자(Consumer)는 메시지가 도착하기를 기다리는 프로그램을 말한다.
- 생산자가 보낸 메시지는 RabbitMQ의 큐에 저장된다. 큐는 우편함 같은 것이다. 많은 생산자가 하나의 큐에 메시지를 보낼 수 있고, 많은 소비자가 하나의 큐로부터 메시지를 받을 수 있다.
- RabbitMQ에는 많은 큐를 만들 수 있고, 큐를 구분하기 위해 이름을 봍인다.

### 연결 수립

아래는 RabbitMQ에 연결을 수립하는 코드이다.

```py
import pika

connection = pika.BlockingConnection(pika.ConnectionParameters('localhost'))
channel = connection.channel()
```

### 큐 만들기

연결이 되어 메시지를 보내면 메시지는 큐로 보내진다. 따라서 메시지를 보내기 전에 큐를 만들어야 한다. 관리자 페이지에서 만들 수도 있고, 프로그램에서 만들 수도 있다. 존재하지 않는 큐에 메시지를 보내면 RabbitMQ는 그냥 버린다.

아래는 hello 큐를 생성하는 코드이다. 큐의 이름이 hello이다.

```py
channel.queue_declare(queue='hello')
```

### 큐에 메시지 보내기

이제 hello 큐에 메시지를 보낼 수 있다.

- RabbitMQ에서는 메시지를 큐에 직접 보내지 않고, 익스체인지(exchange)를 통해서 보낸다. 그래서 메시지를 보내는 함수는 큐를 인자로 받지 않는다.
- 익스체인지에는 큐들이 연결되어 있고, 익스체인지는 메시지를 어떤 큐로 보낼지 판단하는데, 판단할 때 라우팅키 인자를 사용한다. 따라서 메시지를 보내는 함수는 큐가 아닌 익스체인지와 라우팅키를 인자로 전달해야 한다.
- 익스체인지에 대해서는 나중에 다루고, 일단 제일 간단한 디폴트 익스체인지를 사용한다. 큐에 이름이 필요하듯이 익스체인지에도 이름이 필요한데, 디폴트 익스체인지의 이름은 빈 문자열이다.
- 디폴트 익스체인지는 조금 특별하게 동작한다. 보통의 익스체인지는 라우팅키를 보고 어떤 큐에 보낼지 판단하는데, 디폴트 익스체인지는 라우팅 키에 큐의 이름을 명시하여 해당 큐에 보내는 기능을 한다.
- 그래서 우리는 아직 익스체인지와 라우팅키의 개념을 자세히 알지 못하지만, 익스체인지 이름은 빈문자열로, 라우팅키는 hello를 지정하여, hello 큐에 직접 메시지를 보낼 수 있다.

아래와 같이 디폴트 익스체인지를 사용하여 hello 큐에 "Hello world"를 보낸다.

```py
channel.basic_publish(exchange='',
                      routing_key='hello',
                      body='Hello World!')
```

### 연결 닫기

프로그램을 종료할 때는 아래와 같이 연결을 닫아주어야 한다.

```py
connection.close()
```

### 메시지 받기

메시지를 수신하는 프로그램을 만들어보자.

- 당연하게 메시지를 수신하는 프로그램도 연결부터 해야 한다.
- 생산자는 익스체인지에 메시지를 보내고, 익스체인지는 메시지를 전달할 큐를 선택하여 메시지를 전달하고, 소비자는 큐로부터 메시지를 수신한다.
- 소비자가 메시지를 수신하려면 미리 큐에 구독(subscribe)해야 하며, 메시지가 도착하면 구독할 때 등록한 콜백함수가 호출된다.
- 존재하지 않는 큐에 구독을 하면 에러가 발생하므로 먼저 큐를 생성해야 한다. 생산자 또는 소비자 중 어떤 프로그램이 먼저 실행될지 모르므로 보통 생산자와 소비자 모두 큐를 생성하는 코드를 포함시킨다. 이미 존재하면 RabbitMQ가 무시한다.
- 아래는 소비자 프로그램인데, 큐를 정의하고, basic_comsume()으로 큐에 구독하며, 구독할 때 callback() 함수를 등록하고 있다. start_consuming() 함수로 Ctrl+C를 누르기 전까지 계속해서 대기한다.

```py
def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)

channel.queue_declare(queue='hello')

channel.basic_consume(queue='hello',
                      auto_ack=True,
                      on_message_callback=callback)

print(' [*] Waiting for messages. To exit press CTRL+C')
channel.start_consuming()
```

- 콜백함수의 body 파라미터에 메시지가 전송되며, ch, method, properties 파라미터는 나중에 살펴보자.

## 튜토리얼2 Work queue

- 생산자가 작업 요청을 보내고, 소비자가 요청을 처리하는 상황을 생각해보자.
- 클라이언트-서버 모델로 생각해보면 생산자는 클라이언트 측이고, 소비자는 서버측이다.
- 만약 생산자가 작업 요청을 빠르게 보내고, 소비자는 그것을 처리하는데 시간이 걸려서 여러 소비자가 병렬로 요청을 처리하도록 하고 싶은 상황을 가정하자.

### 라운드 로빈 디스패칭(Round-robin dispatching)

- 작업큐(Task queue)는 작업을 쉽게 병렬화할 수 있다.
    예를 들어 소비자 프로세스를 3개 실행하면, 한번에 3개의 메시지를 처리할 수 있다.
- 작업큐에 들어온 메시지를 처음에는 1번 소비자에게 보내고, 두번째 메시지는 2번 소비자에게 보내고, 3번째 메시지는 3번 소비자, 4번째는 다시 1번 소비자 이런식으로 순차적으로 각 소비자에게 보내는 방식을 라운드 로빈이라고 부른다.

### 메시지 Ack 개념

##### 메시지 손실에 대한 문제

- RabbitMQ는 메시지를 소비자에게 보내주고, 큐에서는 삭제할 것이다. 그런데 소비자가 메시지를 처리하다가 에러가 발생하면 어떻게 해야 할까?
- 별로 중요하지 않다면, 에러를 무시하고, 다음 메시지를 처리하면 되겠지만 중요한 메시지라면 재시도를 해야 할 것이다. 일시적인 네트워크 장애로 처리를 못할 수도 있고, 관리자에 의해 소비자 프로그램을 강제 종료시키는 경우도 있을 것이다.

- 정상적으로 처리되지 않은 메시지를 잃어버리지 않기 위해 RabbitMQ는 메시지 Ack를 지원한다. Ack는 소비자가 RabbitMQ에게 메시지를 수신했고, 잘 처리했으니 큐에서 제거해도 된다고 알려주는 개념이다.
- 만약 소비자가 Ack를 보내지 않고, 강제종료 되거나, 연결이 끊어진다면 RabbitMQ는 그것을 다시 큐에 넣어서 다른 소비자에게 보낸다.

##### 자동 Ack

이전에 테스트 했던 소비자 코드는 다음과 같다. auto_ack=True로 설정되어 있어서 자동으로 Ack가 보내진다. 참고로 auto_ack의 기본값은 False이다.

```py
channel.basic_consume(queue='hello',
                      auto_ack=True,
                      on_message_callback=callback)
```

##### 수동 Ack

- Ack를 수동으로 보낼때는 다음과 같이 하면 된다.
- 콜백에서 작업을 처리한 후에 `ch.basic_ack()`를 호출하면 된다.

```py
def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)
    time.sleep( body.count('.') )
    print(" [x] Done")
    ch.basic_ack(delivery_tag = method.delivery_tag)

channel.basic_consume(queue='hello',
                      auto_ack=False,
                      on_message_callback=callback)
```

- Ack는 배달에 의해 전달받은 채널과 동일한 채널에서 보내져야 한다.

### 메시지 내구성(Durability) 개념

- 소비자가 강제종료 되더라도 메시지를 잃지 않는 방법을 살펴보았는데, 아직도 메시지를 잃어버릴 가능성이 있다. 뭔가 특별한 설정을 하지 않았다면, RabbitMQ가 종료되면, 큐와 메시지가 모두 제거된다.

- 큐를 생성할 때 RabbitMQ가 종료되더라도 큐가 살아있도록(durable) 설정해주어야 한다. 아래와 같이 설정한다.

```py
channel.queue_declare(queue='hello', durable=True)
```

- 위의 코드는 hello 큐를 durable하게 설정하는데, 이전에 이미 hello 큐를 durable=False로 만든 상태라서 위의 코드는 에러가 발생한다. 아래와 같이 다른 이름으로 생성하자.

```py
channel.queue_declare(queue='task_queue', durable=True)
```

- 이렇게 RabbitMQ가 종료하더라도 큐가 유지되도록 만들었다. 하지만 메시지는 여전히 제거되는데, 메시지를 보낼때 delivery_mode 속성에 2를 설정하여 처리되지 않은 메시지가 계속해서 남아있도록 할 수 있다. 아래와 같이 설정한다.

```py
channel.basic_publish(exchange='',
                      routing_key="task_queue",
                      body=message,
                      properties=pika.BasicProperties(
                         delivery_mode = 2, # make message persistent
                      ))
```

- 참고로, 메시지를 영속으로 마킹해도, 즉 delivery_mode=2로 설정해도 메시지를 잃어버리지 않는다고 완전히 보장할 수는 없다. RabbitMQ가 메시지를 디스크에 저장하지만, RabbitMQ가 메시지를 받고, 디스크에 저장하는 과정 중에 짧은 시간이 존재한다. RabbitMQ는 모든 메시지에 fsync()를 호출하지는 않으므로, 디스크에 즉시 기록되지 않고 OS의 디스크 캐쉬에만 저장된 상태가 될 수 있다. 우리의 간단한 task_queue 예제에는 충분하지만 영속성 보장이 완전히 강력하지는 않다.
- 만약 더 강력한 보장이 필요하다면, 생산자 confirm을 사용할 수 있다.

### 공정한 분배(Fair dispatch)

- RabbitMQ는 큐에 메시지가 도착하면 바로 분배한다. 소비자가 일하고 있는데도 소비자에게 미리 분배해 놓는다. 그래서 소비자는 아직 처리하지 않은 메시지들이 쌓이게 된다. 빠르게 도착한 10개의 메시지를 소비자 둘에게 분배하는 경우 각 소비자는 정확히 5개씩 처리하게 된다. 이것은 공정하게 보이지만 그렇지 않을 수 있다.
- 어떤 메시지는 처리하는데 10초가 걸리고, 어떤 메시지는 1초 걸린다면, 최악의 경우 첫번째 소비자는 50초 동안 5개를 처리하고, 두번째 소비자는 5초만에 5개를 처리하게 된다. 더 이상의 메시지가 없다면 두번째 소비자는 계속해서 놀게 된다.
- 소비자는 RabbitMQ에 메시지가 도착했다고 바로 분배하지 말고, 최대 n개씩만 분배하도록 요청할 수 있다. 그래서 이미 소비자에게 n개가 부여되었다면 놀고 있는 다른 소비자에게 분배되도록 하는 것이다.
- 만약 소비자가 한 번에 1개만 처리하도록 하려면, 아래와 같이 채널 qos의 prefetch_count를 1로 설정하면 된다.

```py
channel.basic_qos(prefetch_count=1)
```

### 지금까지 다룬 코드를 정리하면 다음과 같다.

```py
# 생산자 new_task.py

import pika
import sys

connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='task_queue', durable=True)

message = ' '.join(sys.argv[1:]) or "Hello World!"
channel.basic_publish(
    exchange='',
    routing_key='task_queue',
    body=message,
    properties=pika.BasicProperties(
        delivery_mode=2,  # make message persistent
    ))
print(" [x] Sent %r" % message)
connection.close()
```

```py
# 소비자 worker.py

import pika
import time

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.queue_declare(queue='task_queue', durable=True)
print(' [*] Waiting for messages. To exit press CTRL+C')


def callback(ch, method, properties, body):
    print(" [x] Received %r" % body)
    time.sleep(body.count(b'.'))
    print(" [x] Done")
    ch.basic_ack(delivery_tag=method.delivery_tag)


channel.basic_qos(prefetch_count=1)
channel.basic_consume(queue='task_queue', on_message_callback=callback)

channel.start_consuming()
```

## 튜토리얼3 발행과 구독(publish/subscribe)

- 이전의 예제는 메시지가 하나의 소비자에게 전달되는 경우를 살펴보았다. 이제 한 메시지가 여러 소비자에게 전달되는 경우를 살펴보자. 이러한 패턴을 발행/구독(publish/subscribe)이라고 한다.
- 로그를 발생하는 프로그램(생산자)과 로그를 처리하는 프로그램(소비자)을 예로 든다. 로그를 처리하는 프로그램은 로그를 디스크에 저장하는 소비자와 로그를 화면에 표시하는 소비자로 서로 다른 소비자로 생각하자.
- 로그 메시지가 모든 소비자에게 브로드캐스트 되는 것을 원한다.

### 익스체인지(Exchange)

- RabbitMQ의 메시지 모델에서 생산자는 큐에 메시지를 보내는 것이 아니라 익스체인지에 보낸다.
- 생산자는 익스체인지에 메시지를 보내기 때문에 어떤 큐에 메시지가 전달되는지 생산자가 알 수는 없다. 생산자의 역할은 익스체인지에 보내는 것 뿐이다.
- 익스체인지는 생산자로부터 메시지를 받아서, 큐에 넣는 역할을 하는데, 특정 큐에 추가할지, 여러 큐에 추가할 지, 그냥 버릴지 등에 대해 판단한다.
- 이러한 규칙들은 익스체인지 타입에 의해 정의된다.
- 4개의 익스체인지 타입이 있다.(direct, topic, headers, fanout).
- 이번 예제에 적합한 fanout 익스체인지에 대해서 살펴보자.

#### fanout

- fanout 익스체인지는 단순히 모든 큐에 브로드캐스트 한다. 이는 우리의 로깅 프로그램에 적절하다.
- fanout 익스체인지를 생성하는 코드는 아래와 같다.

```py
channel.exchange_declare(exchange='logs', exchange_type='fanout')
```

- fanout 익스체인지에 메시지를 보내는 코드는 아래와 같다.

```py

# fanout에서는 routing_key가 의미없다. 무시됨
channel.basic_publish(exchange='logs', routing_key='', body=message)
```

#### 임시 큐들(Temporary queues)

- 이전에 사용했던 hello나 task_queue 예제에서는 큐의 이름이 중요했다. 해당 큐에 보내려면 큐의 이름이 중요했다.
- 우리의 로거 프로그램의 경우에는 큐의 이름은 중요하지 않다. 모든 로그 메시지를 받기만 하면 된다. 그리고 이전의 메시지는 중요하지 않고 현재 발생하는 메시지만 중요하다. 이를 위해 우리는 두 가지가 필요하다.
- 첫번째, Rabbit에 연결할 때마다 새로운 큐를 사용하되, RabbitMQ가 종료되면 큐가 사라지는 것이 좋다. 큐를 생성할 때 durable=False로 설정하면 RabbitMQ가 종료될 때 큐도 제거된다.(durable의 기본값은 False이다.)
- 큐를 생성할 때 큐의 이름에 빈문자열을 명시하면 RabbitMQ가 랜덤한 이름으로 만들어준다.

```py
result = channel.queue_declare(queue='', durable=False) # 랜덤큐 생성

# 랜덤 큐의 이름을 출력
print(result.method.queue) # ex: amq.gen-JzTY20BRgKO-HjmUJj0wLg
```

- 두번째, RabbitMQ가 종료되면 큐가 사라지도록 했지만, 소비자가 RabbitMQ와의 연결을 종료하면 큐가 삭제되기를 원한다. 이를 위해 exclusive=True로 설정하면 된다. 배타적(exclusive)이라는 단어는 다른 프로세스에서 사용할 수 없는, 나만 쓸 수 있는 큐라는 의미이겠다.

```py
result = channel.queue_declare(queue='', exclusive=True)
```

### 바인딩(Bindings)

- fanout 익스체인지와 큐를 만들었다. 이제 생산자가 발행한 메시지가 익스체인지에 도착하면 우리가 만든 큐에 전달되도록 RabbitMQ에 요청해야 할 것이다.
- 익스체인지와 큐가 관계를 맺는 것을 바인딩이라고 한다.

```py
channel.queue_bind(exchange='logs', queue=result.method.queue)
```

### 소스코드

여기까지의 코드를 정리하면 아래와 같다.

아래의 소비자 프로그램에서

- 익스체인지를 만들때 exchange_type=fanout으로 설정하여 바인딩된 모든 큐에 브로드캐스트 되도록 하였다.
- 랜덤한 이름의 큐를 만들기 위해 queue 이름을 빈 문자열로 지정하였고
- 연결이 종료되면 큐가 제거되도록 exclusive=True로 설정하였다.

```py
# 소비자 receive_logs.py

import pika

connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.exchange_declare(exchange='logs', exchange_type='fanout')

result = channel.queue_declare(queue='', exclusive=True)
queue_name = result.method.queue

channel.queue_bind(exchange='logs', queue=queue_name)

print(' [*] Waiting for logs. To exit press CTRL+C')

def callback(ch, method, properties, body):
    print(" [x] %r" % body)

channel.basic_consume(
    queue=queue_name, on_message_callback=callback, auto_ack=True)

channel.start_consuming()

```

- 아래는 생산자 프로그램인데, 소비자와는 달리 바인딩 할 필요가 없다. 그냥 익스체인지에 보내기만 하면 된다.

```py
# 생산자 emit_log.py

import pika
import sys

connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.exchange_declare(exchange='logs', exchange_type='fanout')

message = ' '.join(sys.argv[1:]) or "info: Hello World!"
channel.basic_publish(exchange='logs', routing_key='', body=message)
print(" [x] Sent %r" % message)
connection.close()

```

## 튜토리얼4 라우팅(Routing)

- 이전에 간단한 로깅 시스템을 만들어서 로그 메시지가 모든 소비자에게 브로드캐스트 되도록 했다.
- 이번에 원하는 것은 모든 로그 메시지를 콘솔에 출력하되, 에러 수준의 로그는 파일에 저장하도록 만들고 싶다.

### 바인딩(Bindings)

- 아래는 익스체인지와 큐를 바인딩하는 코드이다.

```py
channel.queue_bind(exchange=exchange_name, queue=queue_name)
```

- 위의 코드는 익스체인지가 큐에 관심 있다로 읽을 수 있다.
- 익스체인지와 큐를 바인딩할 때 routing_key 인자를 지정할 수 있는데, basic_publish()의 routing_key와 혼란을 피하기 위해, 바인딩 할때의 routing_key는 binding key라고 부르자.

```py
channel.queue_bind(exchange=exchange_name,
                   queue=queue_name,
                   routing_key='black') # binding key

```

- 이 바인딩키는 익스체인지 타입에 따라 의미가 달라진다. fanout 익스체인지에서는 그냥 무시된다. fanout은 무조건 브로드캐스팅이라서 바인딩키는 의미가 없다.

### 다이렉트 익스체인지(Direct exchange)

- 이전의 로깅 시스템은 모든 메시지를 모든 소비자에게 보냈다. 이번에는 로깅 레벨로 필터링을 하고 싶다. 예를 들어 에러 수준의 로그만 디스크에 저장하고 싶은 것이다.
- fanout 익스체인지는 무조건 브로드캐스팅이라 유연하지 않다.
- direct 익스체인지를 사용한다. direct 익스체인지의 라우팅 알고리즘은 단순하다. 모든 메시지에는 라우팅키가 존재하는데, 큐의 바인딩 키와 일치하는 것만 해당 큐에 전달하는 방식이다.
- 직관적으로 생각해보면, direct 익스체인지는 이름처럼 메시지를 직접 전달하는 방식의 익스체인지인데, 이 익스체인지에 여러 개의 큐를 바인딩한다. 익스체인지는 메시지의 routing_key와 큐의 routing_key를 비교하여, 동일하면 해당 큐에 전송해준다.
- 동일한 바인딩키를 가진 여러 큐를 하나의 익스체인지에 바인딩할 수 있다.

### 로그 발행 - 생산자

- 이번 예제에서는 fanout 익스체인지를 사용하지 않고, direct 익스체인지를 사용할 것이다. 생산자는 메시지를 보낼 때 routing_key로 로그 레벨을 지정할 것이다.
- direct 익스체인지를 만드는 코드는 다음과 같다.

```py
channel.exchange_declare(exchange='direct_logs', exchange_type='direct')
```

- direct 익스체인지에 메시지를 보내는 코드는 다음과 같다.

```py
log_level="error" # info or warning or error
channel.basic_publish(exchange='direct_logs',
                      routing_key=log_level,
                      body=message)
```

- 이렇게 보내면 일단 'direct_logs'라는 익스체인지에 전송이 될 것이고, 익스체인지는 routing_key를 보고 어떤 큐에 넣을지 판단할 것이다.

### 구독 - 소비자

- 콘솔에 출력하는 소비자는 모든 로그 레벨에 대한 메시지를 받을 것이다.
- 그래서 모든 로그레벨에 대해 바인딩 함수를 호출한다.
- routing_key를 info,warn,error에 대해 각각 설정하고 있다.

```py
# 콘솔에 출력하는 소비자
result = channel.queue_declare(queue='', exclusive=True)
queue_name = result.method.queue

for log_level in ['info','warn','error']:
    channel.queue_bind(exchange='direct_logs',
                       queue=queue_name,
                       routing_key=log_level)
```

- 아래는 에러 로그를 디스크에 저장하는 소비자이다.
- routing_key를 'error'로 설정하고 있다.

```py
# 디스크에 저장하는 소비자
result = channel.queue_declare(queue='', exclusive=True)
queue_name = result.method.queue

log_level='error'
channel.queue_bind(exchange='direct_logs',
                    queue=queue_name,
                    routing_key=log_level)
```

### 소스코드

- 생산자 프로그램은 다음과 같다.

```bash
# 실행
$  python emit_log_direct.py error "Run. Run. Or it will explode."
# => [x] Sent 'error':'Run. Run. Or it will explode.'
```

```py
# emit_log_direct.py - 생산자
import pika
import sys

connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.exchange_declare(exchange='direct_logs', exchange_type='direct')

severity = sys.argv[1] if len(sys.argv) > 1 else 'info'
message = ' '.join(sys.argv[2:]) or 'Hello World!'
channel.basic_publish(
    exchange='direct_logs', routing_key=severity, body=message)
print(" [x] Sent %r:%r" % (severity, message))
connection.close()
```

- 소비자 프로그램은 다음과 같다.

```bash
# 실행
# 에러를 디스크에 저장
$  python receive_logs_direct.py error > logs_from_rabbit.log

# 에러를 콘솔에 출력
$  python receive_logs_direct.py info warn error
```

```py
# receive_logs_direct.py - 소비자
import pika
import sys

connection = pika.BlockingConnection(pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.exchange_declare(exchange='direct_logs', exchange_type='direct')

result = channel.queue_declare(queue='', exclusive=True)
queue_name = result.method.queue

severities = sys.argv[1:]
if not severities:
    sys.stderr.write("Usage: %s [info] [warning] [error]\n" % sys.argv[0])
    sys.exit(1)

for severity in severities:
    channel.queue_bind(
        exchange='direct_logs', queue=queue_name, routing_key=severity)

print(' [*] Waiting for logs. To exit press CTRL+C')


def callback(ch, method, properties, body):
    print(" [x] %r:%r" % (method.routing_key, body))


channel.basic_consume(
    queue=queue_name, on_message_callback=callback, auto_ack=True)

channel.start_consuming()
```

## 튜토리얼5 Topic

- 이전의 예제에서는 무식하게 브로드캐스팅하는 fanout 익스체인지 대신, direct 익스체인지를 사용하여, 로그 메시지를 선택적으로 수신하였다.

- 비록 direct 익스체인지가 로깅 시스템을 개선해주긴 했지만, 여전히 제약사항이 있다.

- 로깅 심각성(info/warn/error)을 기준으로 필터링을 했는데, 이제 로깅 장비(facility)를 필터링 조건으로 넣고 싶다. 로깅 장비는 auth/cron/kern 이 있다. auth는 인증 로그, cron은 크론 로그, kern은 커널 로그 장치(facility)를 의미한다.
- 크론 로그는 error만, 커널 로그는 info/warn/error를 파일에 저장하고 싶다면, 기존의 direct 익스체인지로는 불가능하다.
- 우리의 로깅 시스템을 개선하기 위해 topic 익스체인지를 사용한다.

### topic 익스체인지

- topic 익스체인지에 전달된 메시지는 임의의 routing_key를 가질 수 없다. 점(.)으로 구분된 단어의 목록이어야 한다. 단어는 아무것이나 상관없지만 보통 메시지의 특징을 명시한다. 몇 가지 유효한 라우팅키는 `stock.usd.nyse`,`nyse.vmw`,`quick.orange.rabbit` 같은 것이다.
- 바인딩키는 동일한 형태이어야 한다.
- topic 익스체인지는 메시지를 받으면, 메시지의 routing_key와 큐의 바인딩키를 매칭시켜 큐에 전송할지를 판단한다. 바인딩 키에는 두 가지 특별한 경우가 있다.
    - 별표(\*)는 정확히 하나의 단어를 대체한다.
        - 예시1) `*.orange.*`
        - 예시2) `*.*.rabbit`
    - 해쉬(#)는 zero이상의 단어를 대체한다.
        - 예시1) `lazy.#`
- 메시지의 라우팅 키가 `quick.orange.rabbit`이라면 `*.*.rabbit`에 매치될 것이다. 메시지가 `lazy.orange.elephant`이라면 `*.orange.*`과 `lazy.#`에 매치될 것이다.
- 메시지의 라우팅 키가 `lazy.orange.male.rabbit`인 경우는 4개의 단어인 경우는 `lazy.#`에 매치될 것이다. `*.*.rabbit`에는 매치되지 않는다.

- 만약 큐의 바인딩 키가 `#`이라면 모든 메시지를 받을 수 있다. 이것은 fanout과 동일하다.
- topic 익스체인지에 `*`나 `#`을 사용하지 않으면 direct 익스체인지와 동일하게 동작한다.

### 소스 코드

- 생산자 프로그램은 아래와 같이 실행한다.

```bash
$  python emit_log_topic.py "kern.critical" "A critical kernel error"
```

- 생산자 프로그램의 코드는 다음과 같다
- topic 익스체인지를 사용하고 있다.
- 명령행 인자로 받은 routing_key로 메시지를 보낸다.

```py
# emit_log_topic.py - 생산자
import pika
import sys

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.exchange_declare(exchange='topic_logs', exchange_type='topic')

routing_key = sys.argv[1] if len(sys.argv) > 2 else 'anonymous.info'
message = ' '.join(sys.argv[2:]) or 'Hello World!'
channel.basic_publish(
    exchange='topic_logs', routing_key=routing_key, body=message)
print(" [x] Sent %r:%r" % (routing_key, message))
connection.close()
```

- 소비자 프로그램은 아래와 같이 실행한다.

```bash
$  python receive_logs_topic.py "#"
$  python receive_logs_topic.py "kern.*"
$  python receive_logs_topic.py "kern.*" "*.critical"

```

- 소비자 프로그램의 코드는 다음과 같다
- random한 이름으로 exclusive 한 큐를 사용한다.
- 명령행 인자로 받은 binding_key로 큐와 익스체인지를 바인딩한다.

```py
# receive_logs_topic.py - 소비자
import pika
import sys

connection = pika.BlockingConnection(
    pika.ConnectionParameters(host='localhost'))
channel = connection.channel()

channel.exchange_declare(exchange='topic_logs', exchange_type='topic')

result = channel.queue_declare('', exclusive=True)
queue_name = result.method.queue

binding_keys = sys.argv[1:]
if not binding_keys:
    sys.stderr.write("Usage: %s [binding_key]...\n" % sys.argv[0])
    sys.exit(1)

for binding_key in binding_keys:
    channel.queue_bind(
        exchange='topic_logs', queue=queue_name, routing_key=binding_key)

print(' [*] Waiting for logs. To exit press CTRL+C')


def callback(ch, method, properties, body):
    print(" [x] %r:%r" % (method.routing_key, body))


channel.basic_consume(
    queue=queue_name, on_message_callback=callback, auto_ack=True)

channel.start_consuming()
```
