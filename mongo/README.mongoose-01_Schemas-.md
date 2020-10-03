# Mongoose

- NodeJS에서 MongoDB에 연결하기 위해 mongoose 라이브러리를 사용한다.
- 타입스크립트를 사용한다면 `@types/mongoose`도 설치한다.

```bash
yarn add mongoose
yarn add -D @types/mongoose
```

```json
"dependencies": {
  "mongoose": "^5.10.7",
},
"devDependencies": {
  "@types/mongoose": "^5.7.36",
}
```

- 아래는 타입스크립트로 실제 작성한 Mongoose model이다. 구경하고 문서를 보는 것이 좋을 것 같다.

```ts
// model/user.ts
import { hash, compare } from 'bcryptjs'
import { Schema, model, Document } from 'mongoose'
import { BCRYPT_WORK_FACTOR } from '../config'

interface UserDocument extends Document {
    email: string
    name: string
    password: string
    matchesPassword: (password: string) => Promise<boolean>
}

const userSchema = new Schema(
    {
        email: String,
        name: String,
        password: String,
    },
    {
        timestamps: true,
    },
)

userSchema.pre<UserDocument>('save', async function () {
    if (this.isModified('password')) {
        this.password = await hash(this.password, BCRYPT_WORK_FACTOR)
    }
})

userSchema.methods.matchesPassword = function (password: string) {
    return compare(password, this.password)
}

userSchema.set('toJSON', {
    transform: (doc, { __v, password, ...rest }, option) => rest,
})

export const User = model<UserDocument>('User', userSchema)
```

## Schema

- [Schemas](https://mongoosejs.com/docs/guide.html)에 있는 내용을 참고했다.

### 스키마 정의

- 몽구스에서 모든 것은 스키마로 시작한다. 모든 스키마는 MongoDB 컬렉션에 매핑되고, 컬렉션내의 document의 모양을 정의한다.

```js
 import mongoose from 'mongoose';
  const { Schema } = mongoose;

  const blogSchema = new Schema({
    title:  String, // String is shorthand for {type: String}
    author: String,
    body:   String,
    comments: [{ body: String, date: Date }],
    date: { type: Date, default: Date.now },
    hidden: Boolean,
    meta: {
      votes: Number,
      favs:  Number
    }
  });
```

- 후에 key를 추가하려면, [Schema#add](https://mongoosejs.com/docs/api.html#schema_Schema-add)를 사용할 수 있다.
- 코드에서 정의한 각 키는 SchemaType에 캐스팅된다. 예를 들어 title은 String, date는 Date SchamaType으로 캐스팅 된다.
- 프로퍼티가 타입만을 요구한다면 축약 표기법으로 명시할 수 있다.
- 위의 `meta` 프로퍼티처럼 키는 중첩된 Object로 할당할 수 있다. 키의 값에 type 프로퍼티가 없는 POJO이어야 한다.
- 이 경우, 몽구스는 tree의 leave를 위한 실제 스키마 경로를 생성하고(meta.votes나 meta.favs 같은) tree의 branch는 실제 경로가 없다. 이것은 meta는 자신의 validation을 가질 수 없게 된다. 만약 트리의 validation이 필요하면, 트리에 경로를 생성해야 한다. 이와 관련하여 [Subdocuments](https://mongoosejs.com/docs/subdocs.html) 섹션을 보라. 또 몇 가지 문제를 위해 스키마 타입 가이드의 Mixed 서브 섹션을 읽어보라.
- 허용되는 스키마 타입은 다음과 같다.
  - String
  - Number
  - Date
  - Buffer
  - Boolean
  - Mixed
  - ObjectId
  - Array
  - Decimal128
  - Map

- SchemaType에 대한 자세한 내용은 [여기](https://mongoosejs.com/docs/schematypes.html)를 읽어보라.
- 스키마는 document의 구조를 정의하고 프로퍼티를 캐스팅 할 뿐만 아니라, document의 인스턴스 메소드, 모델의 static 메소드, 복합 인덱스, 미들웨어라고 하는 document 라이프사이클 훅을 정의한다.

### 모델 만들기

- 스키마 정의를 사용하려면 `blogSchema`를 모델로 바꾸야 하고, 우리는 모델로 작업을 한다. 아래와 같이 모델에 스키마를 전달하여 모델을 만든다.

```js
const Blog = mongoose.model('Blog', blogSchema)
```

#### Ids

- 기본으로 몽구스는 `_id` 프로퍼티를 스키마에 추가한다.

```js
const schema = new Schema();

schema.path('_id'); // ObjectId { ... }
```

- 자동으로 추가된 `id` 프로퍼티와 함께, 새로운 document를 생성할 때, 몽구스는 document에 `ObjectId` 타입의 `_id`를 생성한다.

```js
const Model = mongoose.model('Test', schema);

const doc = new Model();
doc._id instanceof mongoose.Types.ObjectId; // true
```

- 몽구스의 기본 `_id`를 당신만의 `_id`로 대체할 수 있다. 주의해야 한다. 몽구스는 `_id`가 없는 document는 저장을 거부하므로, 당신만의 `_id` 경로를 정의한다면 `_id`를 설정하는 것은 당신의 역할이다.

```js
const schema = new Schema({ _id: Number });
const Model = mongoose.model('Test', schema);

const doc = new Model();
await doc.save(); // Throws "document must have an _id before saving"

doc._id = 1;
await doc.save(); // works
```

### Instance methods

- 모델의 인스턴스는 document이다. document는 많은 인스턴트 메소드들을 가지고 있다. 여기에 우리만의 인스턴스 메소드를 추가할 수 있다.

```js
// define a schema
const animalSchema = new Schema({ name: String, type: String });

// assign a function to the "methods" object of our animalSchema
animalSchema.methods.findSimilarTypes = function(cb) {
  return mongoose.model('Animal').find({ type: this.type }, cb);
};
```

- `animal` 인스턴스는 findSimilarTypes() 메소드를 가지게 된다.

```js
const Animal = mongoose.model('Animal', animalSchema);
const dog = new Animal({ type: 'dog' });

dog.findSimilarTypes((err, dogs) => {
  console.log(dogs); // woof
});
```

- 몽구스의 기본 document 메소드를 오버라이팅 하는 것은 예상치 못한 결과가 발생할 수 있다.
- 위의 예는 인스턴스 메소드를 추가하기 위해 Schema.methods 객체를 직접 사용하였다. [Schema.method()](https://mongoosejs.com/docs/api.html#schema_Schema-method) 헬퍼를 사용할 수도 있다.
- 인스턴스 메소드를 function으로 정의하였는데, this는 document를 가리킨다. ES6 화살표 함수는 this 바인딩을 막기 때문에, 화살표 함수로 메소드를 정의하면 안된다.

### Statics

- 모델에 static 함수를 추가할 수 있는데, 두 가지 방법이 있다.
  - schema.statics에 함수 프로퍼티를 추가하는 법
  - [Schame#static()](https://mongoosejs.com/docs/api.html#schema_Schema-static) 함수를 호출하는 법

```js
// Assign a function to the "statics" object of our animalSchema
animalSchema.statics.findByName = function(name) {
  return this.find({ name: new RegExp(name, 'i') });
};

// Or, equivalently, you can call `animalSchema.static()`.
animalSchema.static('findByBreed', function(breed) {
  return this.find({ breed });
});

const Animal = mongoose.model('Animal', animalSchema);
let animals = await Animal.findByName('fido');
animals = animals.concat(await Animal.findByBreed('Poodle'));
```

- schema.methods 와 마찬가지로 화살표 함수를 사용해서는 안된다.

### QueryHelper

- 쿼리 헬퍼 함수들을 추가할 수 있다. 몽구스 쿼리를 위한 인스턴스 메소드 같은 것이다. 쿼리 헬퍼 메소드는 몽구스의 체인 형태의 쿼리 빌더 API를 확장하게 해준다.

```js
animalSchema.query.byName = function(name) {
  return this.where({ name: new RegExp(name, 'i') })
};

const Animal = mongoose.model('Animal', animalSchema);

Animal.find().byName('fido').exec((err, animals) => {
  console.log(animals);
});

Animal.findOne().byName('fido').exec((err, animal) => {
  console.log(animal);
});
```

### Indexes

- MongoDB는 보조 인덱스(secondary index)를 지원한다. 몽구스에서는 스키마 안에서 이 인덱스를 정의할 수 있다. 경로 수준 또는 스키마 수준의 인덱스를 지정할 수 있다.
- 스키마 수준의 인덱스를 정의하는 것은 복합 인덱스를 생성할 때 필요하다.

```js
const animalSchema = new Schema({
  name: String,
  type: String,
  tags: { type: [String], index: true } // field level
});

animalSchema.index({ name: 1, type: -1 }); // schema level
```

- 사용자 애플리케이션이 시작할 때, 몽구스는 스키마에 정의된 각 인덱스에 대해 자동으로 createIndex를 호출하고, 모두 완료(정상 또는 에러)되면 모델의 'index' 이벤트를 발생시킨다.
- 자동인덱스 생성은 개발중에는 유용하지만, 운영환경에서는 사용하지 않아야 한다. 왜냐하면 인덱스를 만드는 작업은 시간이 걸리기 때문이다. 스키마를 정의할 때 autoIndex 옵션을 false로 설정하면 자동 인덱스 생성 기능이 비활성화 된다.

```js
  mongoose.connect('mongodb://user:pass@localhost:port/database', { autoIndex: false });
  // or
  mongoose.createConnection('mongodb://user:pass@localhost:port/database', { autoIndex: false });
  // or
  animalSchema.set('autoIndex', false);
  // or
  new Schema({..}, { autoIndex: false });
```

- 몽구스는 자동 인덱스 생성을 완료하거나 에러가 발생하면 모델에 `index` 이벤트를 발생시킨다.

```js
// Will cause an error because mongodb has an _id index by default that
// is not sparse
animalSchema.index({ _id: 1 }, { sparse: true });
const Animal = mongoose.model('Animal', animalSchema);

Animal.on('index', error => {
  // "_id index cannot be sparse"
  console.log(error.message);
});
```

- [Model#ensureIndex](https://mongoosejs.com/docs/api.html#model_Model.ensureIndexes) 를 확인하라.

### Virtuals

- Virtuals는 MongoDB에는 저장되지 않지만, get/set 할 수 있는 document 프로퍼티이다. getter는 필드를 포매팅 하거나 필드들을 결합할 때 유용하다. setter는 하나의 값을 여러 필드로 분해해서 저장하는 경우에 유용하다.

```js
// define a schema
const personSchema = new Schema({
  name: {
    first: String,
    last: String
  }
});

// compile our model
const Person = mongoose.model('Person', personSchema);

// create a document
const axl = new Person({
  name: { first: 'Axl', last: 'Rose' }
});
```

- 만약 person의 전체 이름을 출력하려고 한다면, 아래와 같이 할 것이다.

```js
console.log(axl.name.first + ' ' + axl.name.last); // Axl Rose
```

- 위의 로직이 여러곳에서 반복된다면 복잡하게 보이므로, fullName 프로퍼티를 정의하는 것이 나을 수 있다. virtual 프로퍼티 getter는 MongoDB에는 저장하지 않는 fullName 프로퍼티를 정의하도록 해준다.

```js
personSchema.virtual('fullName').get(function() {
  return this.name.first + ' ' + this.name.last;
});
```

- 이제 몽구스는 당신의 fullName getter 함수를 호출할 수 있다.

```js
console.log(axl.fullName); // Axl Rose
```

- `JSON.stringify()`는 객체에 `toJSON()` 함수가 있다면 `toJSON()`함수의 호출 결과를 사용한다. 만약 당신이 `toJSON()`이나 `toObject()`를 사용한다면, 몽구스는 기본으로 virtuals를 포함하지 않는다. `{virtuals: true}`를 `toObject()`나 `toJSON()`에 전달하라.

```js
console.log(person.toObject({ virtuals: true })); // { n: 'Val', name: 'Val' }
```

- virtual에 커스텀 setter를 추가할 수 있다. 아래와 같이 한다.

```js
personSchema.virtual('fullName').
  get(function() {
    return this.name.first + ' ' + this.name.last;
   }).
  set(function(v) {
    this.name.first = v.substr(0, v.indexOf(' '));
    this.name.last = v.substr(v.indexOf(' ') + 1);
  });

axl.fullName = 'William Rose'; // Now `axl.name.first` is "William"
```

- virtual 프로퍼티 setter는 다른 validation 전에 적용된다. 그래서 위의 예는 first와 last 프로퍼티가 필수인 경우에도 동작한다.
- 당연하게, virtual 프로퍼티는 쿼리에 사용할 수 없다.

### Alias

- Alias는 virtual의 특별한 타입이다. getter와 setter를 다른 프로퍼티에 그대로 사용할 수 있는 경우에 사용한다. 네트워크 대역폭 절약을 위해, DB에는 짧은 이름으로 저장하고, 코드에서느 가독성을 위해 긴 이름으로 변환할 수 있다.

```js
const personSchema = new Schema({
  n: {
    type: String,
    // Now accessing `name` will get you the value of `n`, and setting `n` will set the value of `name`
    alias: 'name'
  }
});

// Setting `name` will propagate to `n`
const person = new Person({ name: 'Val' });
console.log(person); // { n: 'Val' }
console.log(person.toObject({ virtuals: true })); // { n: 'Val', name: 'Val' }
console.log(person.name); // "Val"

person.name = 'Not Val';
console.log(person); // { n: 'Not Val' }
```

- 또 중첩 경로에서도 별명을 사용할 수 있다.  이것은 중첩 스키마와 subdocument를 사용하기 쉽게 해준다. 전체 중첩 경로 `nested.myProp`을 별명으로 사용하려면 인라인 중첩 경로 별명을 정의해야 할 수 있다.

```js
const childSchema = new Schema({
  n: {
    type: String,
    alias: 'name'
  }
}, { _id: false });

const parentSchema = new Schema({
  // If in a child schema, alias doesn't need to include the full nested path
  c: childSchema,
  name: {
    f: {
      type: String,
      // Alias needs to include the full nested path if declared inline
      alias: 'name.first'
    }
  }
});
```

### Options

- 스키마는 몇 가지 설정항목이 있는데, 생성자나 `set`메소드에 설정옵션을 전달하여 설정할 수 있다.

```js
new Schema({..}, options);

// or

const schema = new Schema({..});
schema.set(option, value);
```

- 설정가능한 옵션은 다음과 같다.
  - autoIndex
  - autoCreate
  - bufferCommands
  - capped
  - collection
  - id
  - _id
  - minimize
  - read
  - writeConcern
  - shardKey
  - strict
  - strictQuery
  - toJSON
  - toObject
  - typeKey
  - useNestedStrict
  - validateBeforeSave
  - versionKey
  - optimisticConcurrency
  - collation
  - selectPopulatedPaths
  - skipVersioning
  - timestamps
  - storeSubdocValidationError

#### 옵션: autoIndex

- 기본으로 몽구스의 `init()`은 `Model.createIndexes()`를 호출하여 스키마의 인덱스를 정의한다. 개발이나 테스트 환경에서는 이런 동작이 유용하다. 다만, 인덱스를 만드는 작업은 시간이 걸리므로, 운영환경에서는 적절하지 않다. autoIndex 기본값은 true이므로, 운영환경에서는 false로 해야 한다.
- 다음과 같이 두 가지 방법이 있다.

```js
const schema = new Schema({..}, { autoIndex: false });
const Clock = mongoose.model('Clock', schema);
Clock.ensureIndexes(callback);
```

```js
mongoose.set('autoIndex', false)
```

#### 옵션: autoCreate

- 몽구스가 인덱스를 만들기 전에, `autoCreate`가 true라면, `Model.createCollection()`을 호출하여 MongoDB에서 collection을 생성한다. `createCollection()` 호출은 collection의 collation 옵션에 따라, 기본 collation을 설정한다. 그리고 capped 스키마 옵션이 설정되었다면, capped collection으로써 collection을 만든다. `audoIndex`와 마찬가지로, `autoCreate`는 개발중에만 유용한 옵션이다.
- `createCollection()`은 이미 존재하는 collection을 변경할 수는 없다. 만약 이미 존재하는 capped가 아닌 collection에 `capped: 1024`로 스키마를 설정한다면, `createCollection()`은 에러를 throw 한다. 일반적으로 운영환경에서 `autoCreate`는 false로 해야 한다.
- `autoCreate` 옵션의 기본값은 false이다.

```js
const schema = new Schema({..}, { autoCreate: true, capped: 1024 });
const Clock = mongoose.model('Clock', schema);
// Mongoose will create the capped collection for you.
```

#### 옵션: bufferCommands

- 몽구스는 연결이 끊어져서 재연결을 하는 동안 명령을 버퍼링한다. 버퍼링을 비활성하려면 false로 설정한다.

```js
const schema = new Schema({..}, { bufferCommands: false });
```

- 스키마의 `bufferCommands` 옵션은 전역 `bufferCommands` 옵션을 대체한다.

```js
mongoose.set('bufferCommands', true);
// Schema option below overrides the above, if the schema option is set.
const schema = new Schema({..}, { bufferCommands: false });
```

#### 옵션: capped

- capped collection은 생성된 데이터 공간을 Queue 형태로 관리하면서 순차적으로 Data를 저장하는 구조. Space가 Full 이 될 경우 가장 오래된 Data 부터 덮어쓰기 함
- 빈 공간 관리를 하지 않기 때문에 Insert 속도가 빠름. Delete 등 없음.

- 몽구스는 MongoDB의 capped collection을 지원한다. MongoDB의 collection을 capped로 지정하기 위해, `capped` 옵션에 document의 최대 크기를 바이트 단위로 설정한다.

```js
new Schema({..}, { capped: 1024 });
```

- capped 옵션을 더욱 상세하게 설정하기 위해 객체로 설정할 수 있다.

```js
new Schema({..}, { capped: { size: 1024, max: 1000, autoIndexId: true } });
```

#### 옵션: collection

- 몽구스는 collection의 이름을 자동으로 복수로 만든다. 예를 들어 `book`이라면 collection은 `books`로 만든다. (`utils.toCollectionName()`) 이름을 자동으로 만들지 말고 직접 지정할때 `collection` 옵션을 사용한다.

```js
const bookSchema = new Schema({..}, { collection: 'book' });
```

#### 옵션: id

- 몽구스는 document의 `_id` 필드에 `id` virtual getter를 할당한다.
- 이 virtual getter는 `_id`가 ObjectId인 경우 hexString으로, 그렇지 않으면 String으로 캐스팅한다.
- `id` 옵션을 false로 설정하면 virtual getter를 만들지 않는다.

```js
// default behavior
const schema = new Schema({ name: String });
const Page = mongoose.model('Page', schema);
const p = new Page({ name: 'mongodb.org' });
console.log(p.id); // '50341373e894ad16347efe01'

// disabled id
const schema = new Schema({ name: String }, { id: false });
const Page = mongoose.model('Page', schema);
const p = new Page({ name: 'mongodb.org' });
console.log(p.id); // undefined
```

#### 옵션: _id

- 몽구스는 스키마에 자동으로 `ObjectId` 타입의 `_id` 필드를 추가한다. `_id`를 추가하지 않으려면 `_id` 옵션을 false로 한다.
- 이 옵션은 subdocument 에서만 사용할 수 있다. `_id` 가 없는 document는 저장시 에러가 발생한다.

```js
// default behavior
const schema = new Schema({ name: String });
const Page = mongoose.model('Page', schema);
const p = new Page({ name: 'mongodb.org' });
console.log(p); // { _id: '50341373e894ad16347efe01', name: 'mongodb.org' }

// disabled _id
const childSchema = new Schema({ name: String }, { _id: false });
const parentSchema = new Schema({ children: [childSchema] });

const Model = mongoose.model('Model', parentSchema);

Model.create({ children: [{ name: 'Luke' }] }, (error, doc) => {
  // doc.children[0]._id will be undefined
});
```

#### 옵션: minimize

- 몽구스는 기본으로 Empty Object를 제거하여 최소화시킨다.

```js
const schema = new Schema({ name: String, inventory: {} });
const Character = mongoose.model('Character', schema);

// will store `inventory` field if it is not empty
const frodo = new Character({ name: 'Frodo', inventory: { ringOfPower: 1 }});
await frodo.save();
let doc = await Character.findOne({ name: 'Frodo' }).lean();
doc.inventory; // { ringOfPower: 1 }

// will not store `inventory` field if it is empty
const sam = new Character({ name: 'Sam', inventory: {}});
await sam.save();
doc = await Character.findOne({ name: 'Sam' }).lean();
doc.inventory; // undefined
```

- 이런 동작은 `minimize` 옵션을 false로 설정하여 변경할 수 있다.

```js
const schema = new Schema({ name: String, inventory: {} }, { minimize: false });
const Character = mongoose.model('Character', schema);

// will store `inventory` if empty
const sam = new Character({ name: 'Sam', inventory: {} });
await sam.save();
doc = await Character.findOne({ name: 'Sam' }).lean();
doc.inventory; // {}
```

- 객체가 Empty 인지 체크하기 위해 `$isEmpty()` 헬퍼를 사용할 수 있다.

```js
const sam = new Character({ name: 'Sam', inventory: {} });
sam.$isEmpty('inventory'); // true

sam.inventory.barrowBlade = 1;
sam.$isEmpty('inventory'); // false
```

#### 옵션: read

- replica 관련 명령인 듯, 나중에 공부하자.

- Allows setting query#read options at the schema level, providing us a way to apply default ReadPreferences to all queries derived from a model.

```js
const schema = new Schema({..}, { read: 'primary' });            // also aliased as 'p'
const schema = new Schema({..}, { read: 'primaryPreferred' });   // aliased as 'pp'
const schema = new Schema({..}, { read: 'secondary' });          // aliased as 's'
const schema = new Schema({..}, { read: 'secondaryPreferred' }); // aliased as 'sp'
const schema = new Schema({..}, { read: 'nearest' });            // aliased as 'n'
```

- The alias of each pref is also permitted so instead of having to type out 'secondaryPreferred' and getting the spelling wrong, we can simply pass 'sp'.

- The read option also allows us to specify tag sets. These tell the driver from which members of the replica-set it should attempt to read. Read more about tag sets here and here.

- NOTE: you may also specify the driver read pref strategy option when connecting:

```js
// pings the replset members periodically to track network latency
const options = { replset: { strategy: 'ping' }};
mongoose.connect(uri, options);

const schema = new Schema({..}, { read: ['nearest', { disk: 'ssd' }] });
mongoose.model('JellyBean', schema);
```

#### 옵션: writeConcern

- Allows setting write concern at the schema level.

```js
const schema = new Schema({ name: String }, {
  writeConcern: {
    w: 'majority',
    j: true,
    wtimeout: 1000
  }
});
```

#### 옵션: shardKey

- The shardKey option is used when we have a sharded MongoDB architecture. Each sharded collection is given a shard key which must be present in all insert/update operations. We just need to set this schema option to the same shard key and we’ll be all set.

```js
new Schema({ .. }, { shardKey: { tag: 1, name: 1 }})
```

- Note that Mongoose does not send the shardcollection command for you. You must configure your shards yourself.

#### 옵션: strict

- 기본값은 true
- strict 옵션은 스키마에 정의되지 않은 필드를 DB에 저장하지 않게 한다.

```js
const thingSchema = new Schema({..})
const Thing = mongoose.model('Thing', thingSchema);
const thing = new Thing({ iAmNotInTheSchema: true });
thing.save(); // iAmNotInTheSchema이 DB에 저장되지 않는다.

// set to false..
const thingSchema = new Schema({..}, { strict: false }); // strict=false
const thing = new Thing({ iAmNotInTheSchema: true });
thing.save(); // iAmNotInTheSchema이 DB에 저장된다.
```

- `document.set()`으로 변경할 수 있다.

```js
const thingSchema = new Schema({..})
const Thing = mongoose.model('Thing', thingSchema);
const thing = new Thing;
thing.set('iAmNotInTheSchema', true); // strict=true
thing.save(); // iAmNotInTheSchema이 DB에 저장되지 않는다.
```

- 모델의 인스턴스 수준에서 설정할 수 있다.

```js
const Thing = mongoose.model('Thing');
const thing = new Thing(doc, true);  // enables strict mode
const thing = new Thing(doc, false); // disables strict mode
```

- The strict option may also be set to "throw" which will cause errors to be produced instead of dropping the bad data.
- NOTE: Any key/val set on the instance that does not exist in your schema is always ignored, regardless of schema option.

```js
const thingSchema = new Schema({..})
const Thing = mongoose.model('Thing', thingSchema);
const thing = new Thing;
thing.iAmNotInTheSchema = true;
thing.save(); // iAmNotInTheSchema is never saved to the db
```

#### 옵션: strictQuery

- 생략
- For backwards compatibility, the strict option does not apply to the filter parameter for queries.

#### 옵션: toJSON

- document의 `toJSON()`이 호출되었을때 적용된다는 점만 빼고, `toObject` 옵션과 동일하다.

```js
const schema = new Schema({ name: String });
schema.path('name').get(function (v) {
  return v + ' is my name';
});
schema.set('toJSON', { getters: true, virtuals: false });
const M = mongoose.model('Person', schema);
const m = new M({ name: 'Max Headroom' });
console.log(m.toObject()); // { _id: 504e0cd7dd992d9be2f20b6f, name: 'Max Headroom' }
console.log(m.toJSON()); // { _id: 504e0cd7dd992d9be2f20b6f, name: 'Max Headroom is my name' }
// since we know toJSON is called whenever a js object is stringified:
console.log(JSON.stringify(m)); // { "_id": "504e0cd7dd992d9be2f20b6f", "name": "Max Headroom is my name" }
```

- 옵션이 9가지 정도 되는데 [여기](https://mongoosejs.com/docs/api.html#document_Document-toObject)를 읽어보라.

#### 옵션: toObject

- document는 `toObject` 메소드를 가지고 있는데, 몽구스 document를 plain Javascript Object로 변환하는 기능을 한다. 이 메소드는 몇 가지 옵션이 있다. 이 옵션을 개별 document에 설정하지 않고, 스키마 수준에서 정의할 수있다. 스키마 수준에서 설정하면 스키마 수준의 모든 document에 적용된다.
- 모든 virtual들을 console.log 출력에 표시하고 싶다면, toObject 옵션에 `{getter:true}`로 설정하라.

```js
const schema = new Schema({ name: String });
schema.path('name').get(function(v) {
  return v + ' is my name';
});
schema.set('toObject', { getters: true });
const M = mongoose.model('Person', schema);
const m = new M({ name: 'Max Headroom' });
console.log(m); // { _id: 504e0cd7dd992d9be2f20b6f, name: 'Max Headroom is my name' }
```

### 옵션: typeKey

- 기본으로 스키마에 `type`을 키로 갖는 객체가 있다면, 몽구스는 그것을 타입 정의로 해석한다.

```js
// Mongoose interprets this as 'loc is a String'
const schema = new Schema({ loc: { type: String, coordinates: [Number] } });
```

- 그러나 geoJSON 같은 애플리케이션에서는 `type` 프로퍼티가 중요하다. 만약 몽구스가 타입정의로 사용할 키를 설정하려면 `typeKey` 옵션을 설정할 수 있다.

```js
const schema = new Schema({
  // Mongoose interpets this as 'loc is an object with 2 keys, type and coordinates'
  loc: { type: String, coordinates: [Number] },
  // Mongoose interprets this as 'name is a String'
  name: { $type: String }
}, { typeKey: '$type' }); // A '$type' key means this object is a type declaration
```

#### 옵션: validateBeforeSave

- document는 저장하기 전에 자동으로 유효성 검사를 한다. `validateBeforeSave`를 false로 설정하여, 유효성 검사를 수동으로 하고, 유효성 검사를 통과하지 않은 객체를 저장할 수 있다.

```js
const schema = new Schema({ name: String });
schema.set('validateBeforeSave', false);
schema.path('name').validate(function (value) {
    return value != null;
});
const M = mongoose.model('Person', schema);
const m = new M({ name: null });
m.validate(function(err) {
    console.log(err); // Will tell you that null is not allowed.
});
m.save(); // Succeeds despite being invalid
```

#### 옵션: versionKey

- 기본값: `__v`
- 몽구스가 document를 생성할 때 versionKey가 설정된다. 이 키는 document의 내부적인 리비전을 담고 있다. `versionKey`의 기본값은 `__v`이며, 이를 변경하고 싶다면 `versionKey` 옵션에 다른 이름을 지정한다.

```js
const schema = new Schema({ name: 'string' });
const Thing = mongoose.model('Thing', schema);
const thing = new Thing({ name: 'mongoose v3' });
await thing.save(); // { __v: 0, name: 'mongoose v3' }

// customized versionKey
new Schema({..}, { versionKey: '_somethingElse' })
const Thing = mongoose.model('Thing', schema);
const thing = new Thing({ name: 'mongoose v3' });
thing.save(); // { _somethingElse: 0, name: 'mongoose v3' }
```

- 몽구스의 기본 버저닝은 완전한 낙관적 동시성([full optimistic concurrency](https://en.wikipedia.org/wiki/Optimistic_concurrency_control)) 해결책은 아니다. 몽구스의 기본 버저닝은 아래에 나오는 배열에서만 동작한다.

```js
// 2 copies of the same document
const doc1 = await Model.findOne({ _id });
const doc2 = await Model.findOne({ _id });

// Delete first 3 comments from `doc1`
doc1.comments.splice(0, 3);
await doc1.save();

// The below `save()` will throw a VersionError, because you're trying to
// modify the comment at index 1, and the above `splice()` removed that
// comment.
doc2.set('comments.1.body', 'new comment');
await doc2.save();
```

- `save()`에 optimistic concurrency 지원이 필요하다면, `optimisticConcurrency` 옵션을 사용할 수 있다.
- document의 versioning은 `versionKey` 옵션을 false로 설정하여 비활성화 할 수 있다. 정확히 무엇인지 알고 있지 않다면 비활성화 하지는 않는 것을 권장한다.

```js
new Schema({..}, { versionKey: false });
const Thing = mongoose.model('Thing', schema);
const thing = new Thing({ name: 'no versioning please' });
thing.save(); // { name: 'no versioning please' }
```

- 몽구스는 `save()`를 호출할때 versionKey를 업데이트 한다.
- `update()`, `findOneAndUpdate()` 등의 호출에서는 version key를 업데이트 하지 않는다. 해결방법으로, 아래의 미들웨어르르 사용할 수 있다.

```js
schema.pre('findOneAndUpdate', function() {
  const update = this.getUpdate();
  if (update.__v != null) {
    delete update.__v;
  }
  const keys = ['$set', '$setOnInsert'];
  for (const key of keys) {
    if (update[key] != null && update[key].__v != null) {
      delete update[key].__v;
      if (Object.keys(update[key]).length === 0) {
        delete update[key];
      }
    }
  }
  update.$inc = update.$inc || {};
  update.$inc.__v = 1;
});
```

#### 옵션: optimisticConcurrency

- Optimistic concurrency는 `find()`로 데이터를 로드하고, `save()`로 저장하는 사이에 document가 변경되지 않음을 보장하기 위한 전략이다.
- 아래의 함수를 보자.

```js
async function markApproved(id) {
  const house = await House.findOne({ _id });
  if (house.photos.length < 2) {
    throw new Error('House must have at least two photos!');
  }

  house.status = 'APPROVED';
  await house.save();
}
```

- `markApproved()`는 isolation이 올바르게 된 것 같지만, 잠재적인 이슈가 있다.  `find()`와 'save()` 사이에 다른 함수가 house의 photo를 제거했다면 어떻게 될까?

```js
const house = await House.findOne({ _id });
if (house.photos.length < 2) {
  throw new Error('House must have at least two photos!');
}

const house2 = await House.findOne({ _id });
house2.photos = [];
await house2.save();

// Marks the house as 'APPROVED' even though it has 0 photos!
house.status = 'APPROVED';
await house.save();
```

- 만약 House 모델의 스키마에 `optimisticConcurrency` 옵션이 설정되어있다면, 위의 코드는 에러를 throw 할 것이다.

```js
const House = mongoose.model('House', Schema({
  status: String,
  photos: [String]
}, { optimisticConcurrency: true }));

const house = await House.findOne({ _id });
if (house.photos.length < 2) {
  throw new Error('House must have at least two photos!');
}

const house2 = await House.findOne({ _id });
house2.photos = [];
await house2.save();

// Throws 'VersionError: No matching document found for id "..." version 0'
house.status = 'APPROVED';
await house.save();
```

#### 옵션: collation

- 기본 collation을 설정한다.
- collation을 잘 모른다면 여기를 참고하자.[collation overview](http://thecodebarbarian.com/a-nodejs-perspective-on-mongodb-34-collations)

```js
const schema = new Schema({
  name: String
}, { collation: { locale: 'en_US', strength: 1 } });

const MyModel = db.model('MyModel', schema);

MyModel.create([{ name: 'val' }, { name: 'Val' }]).
  then(() => {
    return MyModel.find({ name: 'val' });
  }).
  then((docs) => {
    // `docs` will contain both docs, because `strength: 1` means
    // MongoDB will ignore case when matching.
  });
```

### 옵션: skipVersioning

- `skipVersioning`은 버저닝을 제외할 수 있다.
- 정확히 이해한 것이 아니라면 이 옵션을 사용하지 말자.
- subdocument의 경우 fully qualified path를 사용하여 부모 document에 포함된다.

```js
new Schema({..}, { skipVersioning: { dontVersionMe: true } });
thing.dontVersionMe.push('hey');
thing.save(); // version is not incremented
``` 

#### 옵션: timestamps

- `timestamps` 옵션은 몽구스에서 `createdAt`과 `updatedAt` 필드를 스키마에 추가하라고 말한다. 할당된 타입은 Date 이다.
- 기본으로 이 필드의 이름은 `createdAt`과 `updatedAt`이다. 이 필드의 이름을 변경하려면 `timestamps.createdAt`과 `timestamps.updatedAt`을 설정하면 된다.

```js
const thingSchema = new Schema({..}, { timestamps: { createdAt: 'created_at' } });
const Thing = mongoose.model('Thing', thingSchema);
const thing = new Thing();
await thing.save(); // `created_at` & `updatedAt` will be included

// With updates, Mongoose will add `updatedAt` to `$set`
await Thing.updateOne({}, { $set: { name: 'Test' } });

// If you set upsert: true, Mongoose will add `created_at` to `$setOnInsert` as well
await Thing.findOneAndUpdate({}, { $set: { name: 'Test2' } });

// Mongoose also adds timestamps to bulkWrite() operations
// See https://mongoosejs.com/docs/api.html#model_Model.bulkWrite
await Thing.bulkWrite([
  insertOne: {
    document: {
      name: 'Jean-Luc Picard',
      ship: 'USS Stargazer'
      // Mongoose will add `created_at` and `updatedAt`
    }
  },
  updateOne: {
    filter: { name: 'Jean-Luc Picard' },
    update: {
      $set: {
        ship: 'USS Enterprise'
        // Mongoose will add `updatedAt`
      }
    }
  }
]);
```

- 기본으로 몽구스는 `new Date()`를 사용하여 현재 시간을 얻어온다. 현재 시간을 가져오는 이 동작을 변경하려면 `timestamps.currentTime` 옵션을 설정할 수 있다.

```js
const schema = Schema({
  createdAt: Number,
  updatedAt: Number,
  name: String
}, {
  // Make Mongoose use Unix time (seconds since Jan 1, 1970)
  timestamps: { currentTime: () => Math.floor(Date.now() / 1000) }
});
```

#### 옵션:  useNestedStrict

- `update()`, `updateOne()`, `updateMany()`,`findOneAndUpdate()`같은 쓰기 연산들은 top-level의 스키마 strict 모드 설정을 체크한다.

```js
const childSchema = new Schema({}, { strict: false });
const parentSchema = new Schema({ child: childSchema }, { strict: 'throw' });
const Parent = mongoose.model('Parent', parentSchema);
Parent.update({}, { 'child.name': 'Luke Skywalker' }, (error) => {
  // Error because parentSchema has `strict: throw`, even though
  // `childSchema` has `strict: false`
});

const update = { 'child.name': 'Luke Skywalker' };
const opts = { strict: false };
Parent.update({}, update, opts, function(error) {
  // This works because passing `strict: false` to `update()` overwrites
  // the parent schema.
});
```

- `useNestedStrict` 를 true로 설정하면, 몽구스는 child 스키마의 `strict` 옵션을 사용한다.

```js
const childSchema = new Schema({}, { strict: false });
const parentSchema = new Schema({ child: childSchema },
  { strict: 'throw', useNestedStrict: true });
const Parent = mongoose.model('Parent', parentSchema);
Parent.update({}, { 'child.name': 'Luke Skywalker' }, error => {
  // Works!
});
```

#### 옵션: selectPopulatedPaths

- 기본으로 몽구스는 명시적으로 제거하는 경우가 아니라면 , 자동으로 모든 수집된 경로를 `select()` 한다. 

```js
const bookSchema = new Schema({
  title: 'String',
  author: { type: 'ObjectId', ref: 'Person' }
});
const Book = mongoose.model('Book', bookSchema);

// By default, Mongoose will add `author` to the below `select()`.
await Book.find().select('title').populate('author');

// In other words, the below query is equivalent to the above
await Book.find().select('title author').populate('author');
``` 

- 기본으로 채워진 필드를 선택하지 않으려면 `selectPopulatedPaths`를 false로 설정하면 된다.

```js
const bookSchema = new Schema({
  title: 'String',
  author: { type: 'ObjectId', ref: 'Person' }
}, { selectPopulatedPaths: false });
const Book = mongoose.model('Book', bookSchema);

// Because `selectPopulatedPaths` is false, the below doc will **not**
// contain an `author` property.
const doc = await Book.findOne().select('title').populate('author');
```

#### 옵션: storeSubdocValidationError

- 레거시 이유로 단일 중첩 스키마의 하위 경로에 유효성 검사 오류가 있는 경우 몽구스는 단일 중첩 스키마 경로에도 유효성 검사 오류가 있음을 기록한다. 예를 들면

```js
const childSchema = new Schema({ name: { type: String, required: true } });
const parentSchema = new Schema({ child: childSchema });

const Parent = mongoose.model('Parent', parentSchema);

// Will contain an error for both 'child.name' _and_ 'child'
new Parent({ child: {} }).validateSync().errors;
```

- child 스키마에 `storeSubdocValidationError`를 false로 설정하면 몽구스는 parent 에러만 리포트한다.

```js
const childSchema = new Schema({
  name: { type: String, required: true }
}, { storeSubdocValidationError: false }); // <-- set on the child schema
const parentSchema = new Schema({ child: childSchema });

const Parent = mongoose.model('Parent', parentSchema);

// Will only contain an error for 'child.name'
new Parent({ child: {} }).validateSync().errors;
```

### ES6 클래스

- 스키마는 `loadClass()` 메소드가 있다. ES6 클래스로부터 몽구스 스키마를 생성한다.
- [ES6 class methods](https://masteringjs.io/tutorials/fundamentals/class#methods)는 몽구스의 methods가 된다.
- [ES6 class statics](https://masteringjs.io/tutorials/fundamentals/class#statics)는 몽구스의 static이 된다.
- [ES6 getters and setters](https://masteringjs.io/tutorials/fundamentals/class#getterssetters)는 몽구스의 virtual이 된다.

```js
class MyClass {
  myMethod() { return 42; }
  static myStatic() { return 42; }
  get myVirtual() { return 42; }
}

const schema = new mongoose.Schema();
schema.loadClass(MyClass);

console.log(schema.methods); // { myMethod: [Function: myMethod] }
console.log(schema.statics); // { myStatic: [Function: myStatic] }
console.log(schema.virtuals); // { myVirtual: VirtualType { ... } }
```

### Pluggable

- 스키마는 pluggable하다. 재사용 가능한 부분들을 플러그인으로 패키징하여 다른 프로젝트들에서도 이용할 수 있다.

### 더 읽기

- 몽구스 스키마에 대한 또 다른 읽을 만한 글: [alternative introduction to Mongoose schemas](https://masteringjs.io/tutorials/mongoose/schema)
- 몽구스를 최대한 활용하려면 MongoDB 스키마 설계에 대한 기본을 배워야 한다. SQL 스키마 설계는 storage 비용을 최소화 하는 방향으로 설계되었고, MongoDB는 일반 쿼리들을 빠르게 하는 방향으로 설계되었다. 
- MongoDB 스키마 설계를 위한 6가지 규칙을 설명한 [블로그](https://www.mongodb.com/blog/post/6-rules-of-thumb-for-mongodb-schema-design-part-1) 시리즈는 쿼리를 빠르게 만들 수 있는 기본 규칙을 학습할 수 있는 훌륭한 리소스이다.
- MongoDB의 NodeJS 드라이버 개발자인 Christian Kvalheim의 The [Little MongoDB Schema Design Book](http://bit.ly/mongodb-schema-design) 책은 MongoDB 스키마 설계에 대한 상세한 설명을 담고 있다.