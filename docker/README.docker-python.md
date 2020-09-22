# docker 파이썬 환경

### 파이썬 도커 이미지

docker로 파이썬 애플리케이션용 컨테이너를 만들어보니 용량이 꽤 컸다.
python:3의 이미지 크기가 938MB나 되었다. python:3-slim은 165MB이다.

가능하면 python:3-slim을 사용해야 겠다.

### wheel

https://pythonwheels.com/

파이썬 패키지를 설치하려면 소스코드를 컴파일해야 하고 그러면 gcc도 필요해서 docker 이미지가 커지게 된다. wheel이 뭔가 했는데 컴파일된 바이너리 패키지 포맷이다.
egg 포맷을 대체하기 위해 PEP 427에서 소개되었다.
순수 파이썬이나 네이티브 C확장 패키지의 설치가 더 빨라진다.
설치중에 코드 실행을 피하게 해준다.(setup.py 같은거)
c확장의 설치를 할 때도 리눅스나 윈도우,맥등의 컴파일러가 필요하지 않다.
wheel은 .pyc 파일을 생성한다.

예를 들어 psutil 패키지를 설치하려면 gcc가 필요하다. 만약 도커이미지에서 psutil을 설치하려면 gcc를 추가해야 하니까 이미지의 크기가 커지게 된다. psutil을 wheel 패키지로 다운받을 수 있으면 gcc를 설치하지 않아도 되므로 빠르게 설치가 되고, 이미지의 용량도 줄어든다.

### PEX

TODO

### Platter

TODO

### 파이썬 도커이미지의 용량에 대한 내용

https://pythonspeed.com/articles/multi-stage-docker-python/
