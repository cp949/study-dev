# 파이썬 데이터 모델

Fluent Python 책을 보고 정리

## 파이썬 카드 한벌

예제 1-1

```py
import collections
Card = collections.namedtuple('Card', ['rank', 'suit'])

class FrenchDeck:
    ranks = [str(n) for n in range(2,11)] + list('JQKA')
    suits ='spades diamonds clubs hearts'.split()

    def __init__(self):
        self._cards = [Card(rank, suit) for suit in self.suits
                                        for rank in self.ranks]

    def __len__(self):
        return len(self._cards)

    def __getitem__(self, position):
        return self._cards[position]
```

---

#### \_\_len\_\_ 메소드

len() 함수로 FrenchDeck를 호출하면 `FrenchDeck.__len__()` 이 호출된다.
`__len__`은 던더 len 메소드라고 부른다(던더=`double under`)

```py
deck = FrenchDeck()
len(deck) # 52
```

#### \_\_getitem\_\_ 메소드

##### \_\_getitem\_\_ 메소드는 self.\_cards의 `[]` 연산자에 작업을 위임한다.

```ipython
>>> deck[0]
Card(rank='2', suit='hearts')

>>> deck[-1]
Card(rank='A', suit='hearts')
```

##### deck객체는 `[]`를 지원하므로 슬라이싱도 지원한다.

```ipython
# 앞에 3개의 카드 가져오기
>>> deck[:3]
[Card(rank='2', suit='hearts'),
Card(rank='3', suit='hearts'),
Card(rank='4', suit='hearts')]

# 12번 인덱스에서 13개씩 건너뛰어 에이스만 가져오기
>>> deck[12::13]
[Card(rank='A', suit='spades'),
Card(rank='A', suit='diamonds'),
Card(rank='A', suit='clubs'),
Card(rank='A', suit='hearts')]
```

##### deck객체는 `[]`를 지원하므로 랜덤 선택 random.choice를 지원

```ipython
>>> from random import choice
>>> choice(deck)
Card(rank='3', suit='hearts')
```

##### deck객체는 `[]`를 지원하므로 랜덤 선택 reversed를 지원

```ipython
>>> for card in reversed(deck):
>>>     print(card)
Card(rank='2', suit='spades')
Card(rank='3', suit='spades')
Card(rank='4', suit='spades')
...
```

##### in 연산자

\_\_contains\_\_() 메소드가 없다면 in 연산자는 차례대로 검색한다.

```ipython
>>> Card('Q', 'hearts') in deck
True
>>> Card('7', 'beasts') in deck
False
```

##### 정렬

```python
suit_values = dict(spades=3, hearts=2, diamonds=1, clubs=0)
def spades_high(card):
    rank_value = FrenchDeck.ranks.index(card.rank)
    return rank_value * len(suit_values) + suit_values[card.suit]
```

```ipython
>>> for card in sorted(deck, key=spades_high):
>>>     print(card)
```

-   FrenchDeck이 암묵적으로 object를 상속받지만, 상속대신 데이터 모델과 구성을 이용해서 기능을 가져온다.
-   \_\_len()\_\_과 \_\_getitem()\_\_ 특별 메소드를 구현함으로써 FrenchDeck은 표준 파이썬 시퀀스처럼 작동하므로 반복 및 슬라이싱 등의 핵심 언어 기능 및 rankdom.choice(), reversed(), sorted() 함수를 사용한 예제에서 본 것처럼 표준 라이브러리를 사용할 수 있다.
-   구성 덕분에 \_\_len()\_\_과 \_\_getitem()\_\_ 메서드는 모든 작업을 list 객체인 self.\_cards에 떠넘길 수 있다.
-   단, 지금까지의 구현으로는 FrenchDeck를 셔플링할 수는 없다. 불변객체이기 때문이다. 11장에서는 \_\_setitem()\_\_이라는 한줄 짜리 메소드를 추가해서 이 문제를 해결한다.
