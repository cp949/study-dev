# GraphQL Basics

## 시작하기

- GraphQL 한글 문서가 입문하기에 좋다.  
  - 영문으로 된 공식 사이트는 [(https://graphql.org/)](https://graphql.org/)
  - 공식 사이트를 번역한 사이트 [https://graphql-kr.github.io/](https://graphql-kr.github.io/)

- 처음에 GraphQL 입문하기 위해 뭔가를 실행해보고 싶다면 Apollo 서버로 테스트해보는게 가장 간편할 것 같다.

```js
// index.js
const { ApolloServer, gql } = require('apollo-server');

const db = {
  books: [
    { title: 'The Awakening', author: 'Kate Chopin' },
    { title: 'City of Glass', author: 'Paul Auster' },
  ]
};

const typeDefs = gql`
  type Book {
    title: String
    author: String
  }

  type Query {
    books: [Book]
  }
`;


const resolvers = {
  Query: {
    books: () => db.books,
  },
};


const server = new ApolloServer({ typeDefs, resolvers });
server.listen().then(({ url }) => {
  console.log(`🚀  Server ready at ${url}`);
});
```

- 터미널에서 위의 프로그램을 실행하면 브라우저에서 graphql 쿼리를 테스트해 볼 수 있다.

```bash
$ node index.js
```
