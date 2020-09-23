# 타입스크립트 개발환경 구성

```bash
$  npm init -y
$  yarn add -D @types/node typescript ts-node
```

-   tsconfig.json은 npx 명령으로 쉽게 다운로드 받을 수 있다.

```bash
$ npx tsconfig.json
```

-   package.json을 다음과 같이 작성하고

```json
// package.json
"scripts": {
    "start": "ts-node src/app.ts"
},
```

-   src/app.ts 파일에 간단한 코드를 넣는다.

```ts
// src/app.ts
console.log('Hello world')
```

-   `yarn start` 명령으로 코드를 실행한다.

```bash
$  yarn start
# 출력
    yarn run v1.22.5
    $ ts-node src/app.ts
    Hello world
    Done in 1.10s.
```

### nodemon 설치

```
$  yarn add -D nodemon
```

-   package.json을 다음과 같이 수정

```json
"scripts": {
    "watch": "tsc -w",
    "dev": "nodemon dist/app.js",
    "start": "node dist/app.ts",
},
```

-   터미널을 열어서 `yarn watch`를 실행하고, 또 다른 터미널을 열어서 `yarn dev`를 실행한다.
    -   `app.ts`가 변경되었을때 `yarn watch`에 의해 컴파일이 되어 `dist/app.js`파일이 생성되고,
    -   `yarn dev`에 의해 `dist/app.js`가 실행된다.
-   nodemon은 위의 두 과정을 아래와 같이 한번에 실행할 수 있다.

```bash
$  nodemon --watch 'src/**/*.ts' --exec 'ts-node' src/app.ts"`
```

-   최종적으로 다음과 같이 작성했다.
    -   nodemon이나 ts-node는 개발중에만 사용해야 한다.
    -   운영환경에서는 `yarn start`로 실행해야 한다.

```json
"scripts": {
    "dev": "nodemon --watch 'src/**/*.ts' --exec ts-node src/app.ts",
    "start":"node dist/app.js",
    "build": "tsc",
    "build:clean": "yarn clean:pack && yarn clean && yarn build",
    "clean": "rm -rf build",
    "clean:pack": "rm -f *.tgz",
    "lint": "tslint -p .",
    "package": "yarn build:clean && npm pack"
}
```

-   lint를 실행하기 위해 tslint를 추가한다.

```bash
$  yarn add -D tslint
```
