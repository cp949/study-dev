# jq

#### jq 명령어를 몰라서 발생한 일

예전에 어떤 시스템을 만들때 많은 부분을 쉘스크립트로 작성한 적이 있는데
쉘스크립트로는 json 처리를 할 수가 없었다. 정규표현식으로는 json을 파싱하는데 한계가 있다.

그래서 파이썬으로 json을 파싱하는 프로그램을 작성했었는데, jq 명령어를 알았다면, 작성하지 않았을 것 같다.

- jq 명령은 docker의 inspect 명령을 사용하면서 알게 되었다.
- jq 명령은 간단한 듯 싶지만, 그렇게 간단한 것은 아니다. 기능이 매우 많고 공부해야 할 양이 많다.
- jq는 자체적인 문법의 프로그래밍도 지원한다. 하지만 복잡해진다면 jq보다는 그냥 다른 프로그래밍 언어로 작성하는게 더 나을 것이라고 생각한다.
- jq의 기본적인 개념과 사용법만 익혀두려고 한다. json 객체를 필터링해서 원하는 부분을 조회하거나, 새로운 json 객체를 만들어내는 정도면 충분하지 않겠나 싶다.
- 공식 사이트의 문서를 읽는 것이 좋다.
  https://stedolan.github.io/jq/manual/

## Tips

_Tips는 jq 설명을 모두 읽은 후에 이해된다. 자주 사용할 부분이라서 앞부분에 메모해두었다._

### docker inspect와 jq

- `docker inspect`의 결과 json이 너무 길다. 첫 번째 depth의 키들을 살펴보고 싶다.

```bash
$  docker inspect c-was-s0101  | jq '.[] | keys'
```

```json
[
  "AppArmorProfile",
  "Args",
  "HostConfig",
  "HostnamePath",
  "HostsPath",
  "Id",
  "Image",
  "LogPath",
  "Mounts",
  "State"
]
```

- 나는 위에서 마운트 경로만 보고 싶었다.

```bash
$  docker inspect c-was-s0101  | jq '.[] | .Mounts'
```

```json
[
  {
    "Type": "bind",
    "Source": "/app/root/log/s0101",
    "Destination": "/project/logs",
    "Mode": "rw",
    "RW": true,
    "Propagation": "rprivate"
  }
  // ...
]
```

## Basic filters

### Identity: `.`

가장 간단한 필터다. 입력 내용을 그대로 출력한다.

```bash
echo ' "hello" ' | jq '.'
# 결과는 "hello"
```

### Object Identifier-Index: `.foo`, `.foo.bar`

`.foo`는 `inputJSON['foo']`를 찾는다. 없으면 null을 출력한다.

#### ex1 : 기본 .foo 사용법

```bash
{ "foo": 42, "bar": "hello" } | jq '.foo'
# 결과는 42
```

#### ex2 : 없으면 null을 출력한다

```bash
echo ' { "foo": 42, "bar": "hello" } ' | jq '.foo2'
# 결과는 null
```

- 만약 key에 특수문자가 있거나 숫자로 시작하는 경우는 쌍따옴표(`"`)로 감싸야 한다.
- `.foo`는 `.["foo"]`의 축약 표기법이다. `."foo"`도 동일하다.

- 제일 앞에 점(.)으로 시작하는 것은 어떤 key를 찾는 개념이다. `.["foo"]`는 키가 `foo`인 프로퍼티를 찾는 것이고, `.[2]`는 배열의 2번 인덱스 항목을 찾는 개념이다.

- 제일 앞에 점(.)이 없는 형태는 예를 들어, `[.foo]` 는 `.foo`를 찾아서 그 값을 배열로 만드는 개념이다. 즉, 뭔가를 조회하는 것이 아니라 배열을 만들 때(constructor) 사용한다. `[]` 는 javascript에서 배열을 만들때 사용하는 것과 동일하구나 생각하면 되겠다.(나중에 설명함) 어쨌든 jq의 표현식들에서 앞에 점이 있고 없고의 차이가 있으니 주의해야 한다.
- jq로 배열도 만들수 있고, 객체도 만들수 있는데, 문서의 뒷부분에 나온다.

### Array Index: `.[2]`

#### ex1 : 기본 배열 인덱스

INPUT

```json
[
  { "name": "JSON", "good": true },
  { "name": "XML", "good": false }
]
```

```bash
# 배열의 0번 인덱스를 출력
cat input.txt | jq '.[0]'
```

OUTPUT

```json
{
  "name": "JSON",
  "good": true
}
```

#### ex2 : 음수 인덱스 지정도 가능

```bash
# 배열의 뒤에서 두번째 인덱스를 출력
echo '[1, 2, 3]' | jq '.[-2]'
#결과는 2
```

### Array/String Slice: `.[10:15]`

#### ex1 : 기본 슬라이싱 문법

```bash
# 배열의 2 <= index < 4 번 인덱스를 출력
echo ' ["a", "b", "c", "d", "e"] ' | jq '.[2:4]'
# 결과는 ["c", "d"]
```

#### ex2 : 문자열 슬라이싱도 가능

```bash
# 문자열의 2 <= index < 4 번 인덱스를 출력
echo ' "abcdefghi" ' | jq '.[2:4]'
# 결과는 "cd"
```

#### ex3 : 파이썬과 유사한 슬라이싱 문법

```bash
# 배열의 0 <= index < 3 번 인덱스를 출력
echo '  ["a", "b", "c", "d", "e"] ' | jq '.[:3]'
# 결과는  ["a", "b", "c"]
```

#### ex4 : 음수 인덱스로 범위를 설정할 수 있다.

```bash
# 배열의 뒤에서 2번째부터 끝까지 출력
echo ' ["a", "b", "c", "d", "e"] ' | jq '.[-2:]'
# 결과는 ["d", "e"]
```

### Array/Object Value Iterator: `.[]`

`.[index]` 는 배열의 특정 인덱스에 해당하는 항목만 출력하는 문법이다. 콤마로 여러 인덱스를 지정할 수 있다. 인덱스를 지정하지 않으면, 즉 `.[]`은 모든 인덱스를 출력한다.

#### ex1 : 반복자 기본 사용법

INPUT

```json
[
  { "name": "JSON", "good": true },
  { "name": "XML", "good": false }
]
```

```bash
jq '.[]'
```

OUTPUT

```json
{ "name": "JSON", "good": true }

{"name":"XML", "good":false}
```

- 입력 배열에는 항목이 2개 있다. `.[]`은 배열의 모든 항목을 출력하는 표현식이다.

- 출력결과에서 주의할 점은 다중 출력이라는 점이다. 각각의 한줄은 json이고, json을 두 번 출력한 것이다.

#### ex2 : 빈 배열인 경우 출력결과 없음

```bash
echo ' [] ' | jq '.[]'
# 결과는 없음
```

#### ex3 : 콤마로 원하는 인덱스의 값을 출력

```bash
echo '[1, 2, 3, 4, 5]' | jq '.[1,2,3]'
# 결과는 다중 출력이다
2
3
4
```

#### ex4 : 객체에 대해서 `.[]`은 모든 값을 출력

- 배열이 아닌 객체에 대해서 `.[]` 실행하면 모든 키에 대해 값을 출력한다.

```bash
echo '{ "name": "JSON", "good": true }' | jq '.[]'
# 결과는 다중 출력이다
"JSON"
true
```

#### ex4 : 객체에 숫자 인덱스는 불가능

- 배열이 아닌 객체에 대해서 숫자 인덱스는 지정할 수 없다.

```bash
echo '{ "name": "JSON", "good": true }' | jq '.[0]'
# 결과는 Cannot index object with number
```

### 값이 배열인 항목을 출력

#### ex1 : `.key`형태로 배열 출력

```bash
echo '{ "projects": ["jq", "wikiflow"] } ' | jq '.projects'
# 결과는 ["jq", "wikiflow"]
```

#### ex2 : `.key[]`형태로 배열 출력

```bash
echo '{ "projects": ["jq", "wikiflow"] } ' | jq '.projects[]'
# 결과는 다중 출력이다
"jq"
"wikiflow"
```

### Pipe

```bash
echo '[ { "name": "JSON", "good": true } ]' | jq '.[] '
# 결과는 { "name": "JSON", "good": true }
```

- 파이프 기호(`|`) 좌측의 표현식의 결과를 `|` 우측의 표현식의 입력으로 적용한다.

```bash
echo '[ { "name": "JSON", "good": true } ]' | jq '.[] | .name'
# 결과는 "JSON"
```

### Parenthesis

- 괄호는 그룹핑 연산자로 동작한다. 나중에 또 나오니까 대충 이 정도만 알아두자.

```bash
echo 1 | jq '(. + 2) * 5'
# 결과는 15
```

## Types And Values

### 배열 만들기

- `[]`는 json에서 배열을 만드는데 사용한다. 파이프라인을 포함해서, 배열의 요소는 어떤 jq 표현식이라도 가능하다. 표현식에 의해 생성된 모든 결과물들은 하나의 배열에 포함된다. `[.foo, .bar, .baz]` 같이 정해진 크기의 배열을 만들 수도 있고, `[.items[].name]` 같이 필터의 결과물을 배열로 만들 수도 있다.

- 콤마(`,`) 연산자를 이해했다면, `jq`의 배열 문법을 다른 관점에서 살펴볼 수 있다. `[1,2,3]`은 콤마로 구분된 배열을 위한 내장된 문법을 사용하는 것이 아니고, `[]`연산자를 표현식 `1,2,3`에 적용하는 것이다. jq에서 `1,2,3`은 세 개의 서로 다른 결과를 생성하는 문법이다.
- 만약 4개의 결과를 생성하는 X 필터가 있다면, `[X]`는 4개의 결과를 하나의 결과물-배열로 만들어낸다.

```bash
echo '{ "user": "stedolan", "projects": ["jq", "wikiflow"] }' | jq '[ .user, .projects[] ]'
# 출력은 ["stedolan", "jq", "wikiflow"]
```

참고로 만약 필터를 아래와 같이 작성했다면,

```bash
jq '.user, .projects[]'
```

출력은 3개의 결과물이 만들어진다.

```json
"stedolan"
"jq"
"wikiflow"
```

### 객체 만들기

JSON에서 처럼, `{}`는 객체를 생성한다 ( `{"a":42, "b":17}` )

- 만약 키가 'idenfier-like'라면, 따옴표는 생략할 수 있다. 키 표현식으로 참조되는 변수는 변수의 값을 키로 사용한다.(`identifier-like`는 프로그래밍 언어에서 변수이름으로 사용할 수 있는 규칙을 말한다. 숫자로 시작하면 안되고, 특수기호 없고, 알파벳, 숫자, 언더바로 구성되는 등의 규칙 같은 거)

#### ex: 값은 모든 표현식이 가능하다.

```bash
echo ' { "bar": 42, "baz": 43 } ' | jq '{ foo: .bar }'
# 결과는 {"foo": 42}
```

#### ex: 축약된 형태의 표기법

INPUT

```json
{ "user": "stedolan", "title": "JQ Primer" }
```

```bash
jq '{ user: .user, title: .title }'

# or

jq '{ user, title }'
```

OUTPUT

```json
{ "user": "stedolan", "title": "JQ Primer" }
```

#### ex: 다중 출력

표현식 중 하나가 다중 출력 형태인 경우 다중 객체가 만들어진다.

```json
{ "user": "stedolan", "titles": ["JQ Primer", "More JQ"] }
```

```bash
jq '{user, title: .titles[]}'
```

OUTPUT

```json
{"user":"stedolan", "title": "JQ Primer"}
{"user":"stedolan", "title": "More JQ"}
```

#### ex : 키부분의 표현식

- 키 부분을 표현식으로 생성하려면 괄호로 감싸야 한다.

```json
{ "user": "stedolan", "titles": ["JQ Primer", "More JQ"] }
```

```bash
jq '{ (.user) : .titles }'
```

OUTPUT

```json
{ "stedolan": ["JQ Primer", "More JQ"] }
```

- 변수를 키로 사용하면 변수의 값이 키가 된다. 값을 명시하지 않으면, 키와 값이 변수로 된다.

다음과 같이 필터를 작성한 경우

```
"f o o" as $foo | "b a r" as $bar | {$foo, $bar:$foo}
```

출력은 아래와 같다.

```json
{ "f o o": "f o o", "b a r": "f o o" }
```

#### Recursive Descent : `..`

`..`은 재귀적으로 아래로 내려가면서 모든 값을 생성한다.

#### ex1 : 재귀적으로 모두 출력

INPUT

```json
{
  "title": "JQ Primer",
  "user": {
    "age": 12,
    "home": {
      "address1": "seoul"
    }
  }
}
```

```bash
jq '..'
```

OUTPUT

```json
{
  "title": "JQ Primer",
  "user": {
    "age": 12,
    "home": {
      "address1": "seoul"
    }
  }
}

"JQ Primer"

{
  "age": 12,
  "home": {
    "address1": "seoul"
  }
}

12

{ "address1": "seoul" }

"seoul"
```

#### ex2 : age부분만 찾기

```bash
jq ' .. | .age? '
```

OUTPUT

```json
null
12
null
```

- 나중에 나오긴 하지만, null을 제거하고 싶다면 아래와 같이 할 수 있다.

```bash
jq ' .. | .age? | select ( . != null )? '
```

## Builtin operators and functions

### Addition `+`

`+`는 두 개의 필터에 대해 그들을 같은 입력으로 적용하고, 결과물을 더한다.

- "adding"의 의미는 각 타입별로 다르다
  - Number는 일반 숫자 연산으로써 더한다.
  - Array는 배열을 합친다.
  - String은 문자열을 결합한다.
  - Object는 두 객체를 머지한다. 두 객체가 같은 키를 갖고 있다면 연산자의 우측에 있는 놈의 것으로 적용된다.
  - null은 어떤 값에도 더해질 수 있으며, 결과에 영향을 주지 않는다.

```bash
$  echo ' {"a": 7} ' | jq '.a + 1'
# 결과는 8
```

```bash
$  echo ' {"a": [1,2], "b": [3,4]} ' | jq '.a + .b'
# 결과는 [1,2,3,4]
```

```bash
$  echo ' {"a": 1} ' | jq '.a + null'
# 결과는 1
```

```bash
$  echo ' {} ' | jq '.a + 1'
# 결과는 1
```

```bash
$  echo ' null ' | jq '{a: 1} + {b: 2} + {c: 3} + {a: 42}'
# 결과는 {"a": 42, "b": 2, "c": 3}
```

### Substraction `-`

- 숫자의 뺄셈

```bash
$  echo ' {"a":3} ' | jq '4 - .a'
# 결과는 1
```

- 배열의 뺄셈은 항목을 제거하는 개념이다

```bash
$  echo ' ["xml", "yaml", "json"] ' | jq '. - ["xml", "yaml"]'
# 결과는 ["json"]
```

### Multiplication, division, modulo: `* / %`

- 이 연산자들은 두 숫자에 대해서는 연산자 그대로 연산을 한다.

```bash
$  echo ' 5 ' | jq '10 / . * 3'
# 결과는 6
```

- 0으로 나누면 에러가 발생한다.

```bash
echo 0 | jq ' ( 1 / . ) '
# 결과는 cannot be divided because the divisor is zero
```

문서에는 0으로 나누면 에러가 발생한다고 적어놓고, 아래의 경우에는 에러가 발생하지 않는 것처럼 적혀있다. 실제로 에러가 발생한다.

```bash
echo ' [1,0,-1] ' | jq ' .[] | ( 1 / . ) '
# 출력 결과
1
jq: error (at <stdin>:1): number (1) and number (0) cannot be divided because the divisor is zero
```

끝에 물음표를 붙이면 에러가 무시된다. 에러가 발생한 부분은 출력하지 않는다.

```bash
echo ' [1,0,-1] ' | jq ' .[] | ( 1 / . )?'
# 출력 결과
1
-1
```

- string의 곱셈은 주어진 숫자만큼 반복한다. 만약 문자열에 0을 곱하면 null 이 된다.

```bash
echo ' "ab" ' | jq ' . * 3 '
# 결과는 "ababab"
```

- string의 나눗셈은 split이다. (그냥 split 함수를 사용하는 것이 나을 것 같다.)

```bash
echo ' "a, b,c,d, e" ' | jq '. / ", "'
# 결과는 ["a","b,c,d","e"]
```

- 객체를 곱하는 것은 곱셈이 아니다. 값부분에 숫자가 있더라도 곱셈을 하지 않는다. 재귀적으로 객체를 Merge 한다.

```bash
echo 'null' | jq '{"k": {"a": 1, "b": 2}} * {"k": {"a": 0,"c": 3}}'
# 결과는 객체의 머지임 {"k": {"a": 0, "b": 2, "c": 3}}
```

### length

- length는 각 객체의 타입별로 다르게 동작한다.
- 배열의 경우는 배열의 길이

```bash
echo '[1,2,3]' | jq 'length'
# 결과는 3
```

- 문자열의 경우는 문자열의 길이

```bash
echo '"hello"' | jq 'length'
# 결과는 5
```

```bash
echo '"가나다라"' | jq 'length'
# 결과는 4
```

- 객체의 경우는 프로퍼티의 개수

```bash
$  echo ' ["xml", "yaml", "json"] ' | jq 'length'
# 결과는 3
```

- null인 경우는 0

```bash
echo null | jq 'length'
# 결과는 0
```

- 숫자인 경우는 숫자 그대로가 나온다.(문서에는 적혀있지 않아서 테스트 해봤다)

```bash
echo '100' | jq 'length'
# 결과는 100
```

### utf8bytelength

내 리눅스에서는 동작하지 않는다

```bash
echo '"\u03bc"' | jq 'utf8bytelength'
```

OUTPUT

```
jq: error: utf8bytelength/0 is not defined at <top-level>, line 1:
utf8bytelength
jq: 1 compile error
```

### keys, keys_unsorted

- keys는 객체가 주어졌을때 객체의 키들을 배열로 리턴한다. 키는 알파벳 순으로 정렬된다. keys_unsorted는 key를 정렬하지 않는다.

```bash
echo '{"abc": 1, "abcd": 2, "Foo": 3}' | jq 'keys'
# 결과는 ["Foo", "abc", "abcd"]
```

- 배열이 주어지면, 배열의 인덱스가 결과물이다.

```bash
echo '[42,3,35]' | jq 'keys'
# 결과는 [0,1,2]
```

### has(key)

- 입력 객체에 주어진 키가 존재하는지 여부를 true/false로 출력한다.

```bash
echo ' {"foo": 42} ' | jq 'has("foo")'
# 출력은 true
```

```bash
echo ' {"foo": 42} ' | jq 'has("bar")'
# 출력은 false
```

- 만약 입력 객체가 배열이라면 인덱스로 체크해야 한다.

```bash
echo ' [1,2,3] ' | jq 'has(2)'
# 출력은 true
```

```bash
echo ' [1,2] ' | jq 'has(2)'
# 출력은 false
```

### in

- has의 반대라고 생각하면 된다. has는 어떤 객체가 주어지고, 그 객체에 어떤 프로퍼티가 존재하는지를 체크하는 것이니까, in은 어떤 프로퍼티들이 주어지고, 이 프로퍼티가 어떤 객체에 존재하는지를 체크하는 것이다.

```bash
echo ' "foo" ' | jq ' in({"foo": 42})'
# 출력은  true
```

```bash
echo ' ["foo", "bar"] ' | jq '.[] | in({"foo": 42})'
# 출력은 다중 출력이다
true
false
```

- 배열에 대해서는 인덱스 기반으로 동작한다.

```bash
echo ' 0 ' | jq ' in ([100,200]) '
# 출력은 true
```

```bash
echo ' [2, 0] ' | jq ' .[] | in ([100,200]) '
# 출력은 다중 출력이다
false
true
```

### map(x), map_values(x)

map을 알아보기 전에 예제를 먼저 살펴보자

```bash
echo [1,2,3] | jq '[ .[] | . + 10 ]'
# 출력은 [11, 12, 13]
```

- 위의 예에서 `.[]`은 1,2,3 세 개를 출력하고, `. + 10`은 각 항목에 덧셈을 한다. 그리고 전체 필터가 `[]`로 감싸져있으므로, 각각의 덧셈 결과가 하나의 배열로 합쳐진다.
- 아래의 map은 위의 동작과 정확히 일치한다.

```bash
echo [1,2,3] | jq 'map(. + 10)'
# 출력은 [11, 12, 13]
```

- `map(x)`은 주어진 배열의 각 항목에 대해 x 필터를 적용하고, 그 결과를 배열로 만든다.
- `map_values(x)`는 배열이 아닌 객체에 대해 동작한다.

```bash
echo ' {"a": 1, "b": 2, "c": 3} ' | jq 'map_values( . + 1 )'
# 출력은 {"a": 2, "b": 3, "c": 4 }
```

### path(path_expression)

#### 배열 경로 표기법의 이해

- jq에서 `{"foo": { "bar": 123 }}` 객체의 `.bar`값을 얻기 위해서 `.foo.bar` 형태로 표기한다. `.foo.bar`가 프로퍼티의 경로를 표시하는 문법인 셈이다.
- jq에서는 경로를 표시하기 위해 배열 형태로도 정의할 수도 있다.
  위의 `.foo.bar`는 `["foo", "bar"]`와 동일하다.
- 만약 `bar`가 배열이라면 `{"foo": {"bar": [100, 200]}}` 에서 `["foo", "bar", 0]`은 100을 가리키고, `["foo","bar",1]`은 200을 가리킨다.

#### path 함수

- path 함수는 jq의 기본 경로 표기법을 배열 경로 표기법으로 변환해주는 함수이다.

```bash
echo null | jq 'path(.a[0].b)'
# 결과는 ["a", 0, "b"]
```

### getpath(PATHS)

- getpath는 배열 경로 표기법으로 주어진 객체의 값을 출력하는 함수이다. 아래 예제를 보자.

```bash
echo ' {"a":{"b":10, "c":11}} ' | jq 'getpath(["a","b"], ["a","c"])'

# or

echo ' {"a":{"b":10, "c":11}} ' | jq '.a.b, .a.c'
# 결과는 다중 출력
10
11
```

- 입력이 null이면 출력도 null이다.

```bash
echo null | jq 'getpath(["a","b"])'
# 결과는 null
```

### setpath(PATHS; VALUE)

- getpath는 값을 꺼내오는 것이고, setpath는 값을 설정하는 것이겠다.
- 존재하지 않는 경우는 새로 만든다는 점에 주목해야 한다. 그래서 입력이 null일지라도 path에 맞게 객체나 배열이 만들어진다.

```bash
echo null | jq 'setpath(["a","b"]; 1)'
# 출력은 {"a": {"b": 1}}
```

```bash
echo '{"a":{"b":0}}' | jq 'setpath(["a","b"]; 1)'
# 출력은 {"a": {"b": 1}}
```

```bash
echo null | jq 'setpath([0,"a"]; 1)'
# 출력은 [{"a":1}]
```

### del(path_expression)

- 주어진 경로를 제거한다

```bash
echo '{"foo": 42, "bar": 9001}' | jq 'del(.foo)'
# 출력은 {"bar": 9001}
```

```bash
echo ' ["foo", "bar", "baz"] ' | jq 'del(.[1, 2])'

# 출력은 ["foo"]
```

### delpaths(PATHS)

- 배열 경로 표기법 기준으로 항목을 삭제한다.

```bash
echo '{"a":{"b":1},"x":{"y":2}}' | jq 'delpaths([["a","b"]])'
# 출력은 {"a":{},"x":{"y":2}}
```

### to_entries

key,value 형태로 만들어준다. 출력 결과를 보면 이해가 된다.

```bash
echo '{"a": 1, "b": 2}' | jq 'to_entries'
# 출력은 [{"key":"a", "value":1}, {"key":"b", "value":2}]
```

### from_entries

key,value 형태로부터 객체를 만든다. 출력 결과를 보면 이해가 된다

```bash
echo '[{"key":"a", "value":1}, {"key":"b", "value":2}]' | jq 'from_entries'
# 출력은 {"a": 1, "b": 2}
```

### with_entries

출력 결과를 보면 이해가 된다.

```bash
echo '{"a": 1, "b": 2}' | jq 'with_entries(.key |= "KEY_" + .)'
# 출력은 {"KEY_a": 1, "KEY_b": 2}
```

### select(boolean_expression)

특정 조건이 맞는 항목만 출력한다.

```bash
echo '[1,5,3,0,7]' | jq 'map(select( . >= 2 ))'
# 출력은 [5,3,7]
```

```bash
echo '[{"id": "first", "val": 1}, {"id": "second", "val": 2}]' | jq '.[] | select(.id == "second")'
# 출력은 {"id": "second", "val": 2}
```

### paths

```bash
echo '[1,[[],{"a":2}]]' | jq 'paths'
# 출력은 다중 출력
[0]
[1]
[1,0]
[1,1]
[1,1,"a"]
```

##### paths(numbers) 숫자값이 있는 항목만

```bash
echo '[1,[[],{"a":2}]]' | jq 'paths(numbers)'
# 출력은 다중 출력
[0]
[1,1,"a"]
```

##### paths(scalars), leaf_paths 말단 노드만

```bash
echo '[1,[[],{"a":2}]]' | jq 'paths(scalars)'
# 출력은 다중 출력
[0]
[1,1,"a"]
```

- leaf_paths는 paths(scalars)와 동일하다.

```bash
echo '[1,[[],{"a":2}]]' | jq 'leaf_paths'
# 출력은 다중 출력
[0]
[1,1,"a"]
```

# flatten, flatten(depth)

```bash
echo '[1, [2], [[3]]]' | jq 'flatten'
# 출력은 [1, 2, 3]
```

```bash
echo '[1, [2], [[3]]]' | jq 'flatten(1)'
# 출력은 [1, 2, [3]]
```

```bash
echo '[1, [2], [[3]]]' | jq 'flatten(0)'
# 출력은 [1,[2],[[3]]]
```

```bash
echo '[[]]' | jq 'flatten'
# 출력은 []
```

```bash
echo '[{"foo": "bar"}, [{"foo": "baz"}]]' | jq 'flatten'
# 출력은 [{"foo": "bar"}, {"foo": "baz"}]
```
