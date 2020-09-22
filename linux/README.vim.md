# vim tips

한글로 된 vim 문서

[iBooks로 읽는 프랙티컬 Vim 2판](https://nolboo.kim/practical-vim/)

[밤앙개의 vim강좌](https://blog.naver.com/nfwscho/220407221737)

[Practical Vim(영어)](https://fzheng.me/2018/03/24/practical-vim-registers/)

### tab

vim 탭 기능을 아래와 같이 매핑해서 사용한다.(나의 개인취향)

```vim
tab navigation mappings
nnoremap tn  :tabnext<CR>
nnoremap tp  :tabprev<CR>
nnoremap tt  :tabedit<Space>
nnoremap tm  :tabm<Space>
nnoremap tq  :tabclose<CR>
nnoremap t1 1gt
nnoremap t2 2gt
nnoremap t3 3gt
nnoremap t4 4gt
nnoremap t5 5gt
nnoremap t6 6gt
nnoremap t7 7gt
nnoremap t8 8gt
nnoremap t9 9gt
```

참고할 문서
[Vim의 탭은 그렇게 쓰는 게 아니다. 버퍼와 탭의 사용법](https://bakyeono.net/post/2015-08-13-vim-tab-madness-translate.html)

### some

- f{char}는 다음 특정 문자로 커서를 이동한다.
- CTRL+a는 커서 밑의 숫자값을 하나 증가시키고, CTRL+x는 감소시킨다.
  커서 밑이 숫자가 아닐 때는 이후에 있는 숫자로 이동해 앞에 입력한 숫자만큼 증감한다.
- 0이 앞에 있는 숫자는 8진수로 해석하기 때문에 `007+001 = 010`이다. `:set nrformats=`하면 십진수로 해석한다.
- Visual Mode에서 `v`는 character-wise, `V`는 line-wise, `CTRL+v`는 block-wise Visual Mode이다. 한 가지 모르고 있었던 것은 `gv`명령이다. 마지막 Visual Selection을 다시 선택해준다.
- vim 내에서 어떤 디렉토리 안의 파일목록을 볼 수 있는데, vim에 기본으로 내장된 netrw 플러그인이 하는 일이다.`:edit .`으로 열 수 있다.
- `<c-r>`은 마지막으로 검색한 패턴을 보관하고 있다. last-search register
- `:%s//New String/g` 라고 하면 마지막으로 검색한 패턴으로 substite한다.
  `:%s/<c-r>/New String/g`라고 해도 된다.

### Display Lines와 Real Lines

- vim에서 한줄이 매우 길면 화면의 영역을 벗어나는 부분이 안보이게 되는데 `:set wrap`으로 여러 줄에 표시하게 할 수 있다.
- 너무 긴 한줄을 여러 라인에 걸쳐서 표시되는 라인을 Display Line이라고 한다.
- `j`명령은 아래 줄로 이동하는데, 이것은 Real Line을 기준으로 이동한 것이다. 만약 `gj`명령은 Display Line을 기준으로 이동한다.
- `j,k,0,^,$`가 Real Line을 기준으로 커서를 이동하는 것과 동일한 방식으로
  `gj, gk, g0, g^, g$`는 Display Line을 기준으로 동작한다.

### buffer

- 열린 파일은 모두 버퍼로 인식된다.
- 버퍼목록을 보는 명령은 `:ls` 또는 `:buffers`이다.
- 2번 버퍼로 이동하는 명령은 `2<C-^>`이다. (2를 누르고 컨트롤 6을 누르면 된다). 그 외에도 아래의 버퍼 관련 명령이 있다.

```vim
:bprevious
:bnext
:bfirst
:blast
:bdelete N1 N2 N3
:buffers (:ls와 동일)
:buffer N
```

### find

`:find`로 경로 전체를 입력하지 않고 파일명만으로 파일을 열 수 있다.
탭을 누르면 자동완성도 해주므로 전체 파일명을 모두 외우지 않아도 된다.

이 기능을 사용하기 위해서는 먼저 path를 설정해야 한다.

```vim
set path+=app/**
```

`**`는 `app/`아래의 모든 서브디렉토리이다.
같은 이름을 가진 파일이 여러 개라면 탭키를 누를때 마다 전체 경로와 파일명을 보여준다. 탭키로 전체 파일 경로로 확장하지 않고 엔터키를 누르면 처음 일치 파일을 연다. `wildmode`설정을 기본값 `full`에서 변경하면 탭-완성 동작이 조금 다를 수 있다.

### :Commands

fzf 플러그인에 있는 명령인데 좋아

```
:Commands
```

# install vim-plug

몇몇 플러그인은 vim 8.0이상에서 동작한다

```
curl -fLo ~/.vim/autoload/plug.vim --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

```

### specify vim plugins in .vimrc

```
$ cat ~/.vimrc
call plug#begin('~/.vim/plugged')

Plug 'junegunn/vim-easy-align'
Plug 'stephpy/vim-yaml'

Plug 'editorconfig/editorconfig-vim'
Plug 'itchyny/lightline.vim'
Plug 'junegunn/fzf'
Plug 'junegunn/fzf.vim'
Plug 'mattn/emmet-vim'
Plug 'scrooloose/nerdtree'
Plug 'terryma/vim-multiple-cursors'

Plug 'tpope/vim-surround'
Plug 'vim-scripts/taglist.vim'
Plug 'chr4/nginx.vim'

" unused
" Plug 'tpope/vim-eunuch'
" Plug 'w0rp/ale'
" Plug 'airblade/vim-gitgutter'

call plug#end()
```

### install vim-plugins

- Reload .vimrc and :PlugInstall to install plugins.

# plugins

### fzf

```
:Files<CR>
```

파일 목록을 보여준다(`:Files`).

또는 특정 단어가 포함된 라인만 필터링해서 보여준다(`:Lines`).

vimrc에 아래와 같이 매핑해서 사용한다.

```vim
" file finder mapping
nmap ,e :Files<CR>
" general code finder in current file mapping
nmap ,f :BLines<CR>
" the same, but with the word under the cursor pre filled
nmap ,wf :execute ":BLines " . expand('<cword>')<CR>
" general code finder in all files mapping
nmap ,F :Lines<CR>
" the same, but with the word under the cursor pre filled
nmap ,wF :execute ":Lines " . expand('<cword>')<CR>
" commands finder mapping
nmap ,c :Commands<CR>

```

### vim-multiple-cursors

단어위에 커서를 올리고 CTRL+n을 누르면 같은 단어에 여러 커서가 생겨서 동시에 수정할 수 있다.
여러 단어에 커서가 올라간 상태에서

- I는 Insert
- A는 Append
- c는 change 텍스트
- d는 그냥 지우기

### NERDTree

```
:NERDTreeToggle<CR>
```

왼쪽 창에 파일 트리가 보여진다

vimrc에 아래와 같이 매핑해서 사용한다.

```
map <C-o> :NERDTreeToggle<CR>
```

### editorconfig

홈디렉토리에 .editorconfig 파일을 참조한다.

### vim-easy-plugin

생각보다 필요한 경우가 많다.

```vim
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)
```

아래의 내용이 있을 때

```
Paul Mc 1942
George Harrison 1943
```

명령모드에서 대문자 `V`를 눌러서 여러 줄을 선택하고(visual mode)
`ga`를 누르면 easy-align 모드가 시작된다.

또는 명령모드에서 `ga` 입력후 엔터를 누르면 easy-align 모드가 시작된다.

easy-align 모드에서 `<Space>`를 누르면 아래와 같이 정렬된다.

```
Paul   Mc 1942
George Harrison 1943
```

easy-align 모드에서 `2<Space>`를 누르면 아래와 같이 정렬된다.

```
Paul   Mc       1942
George Harrison 1943
```

`2<Space>`에서 2는 두 개의 컬럼을 의미하는데, `*<Space>`를 누르면
모든 컬럼을 정렬한다.

아래는 공백 보다는 `=`기호로 정렬하는 것이 필요하다.

```
apple = red
grass += green
sky -= blue
```

easy-align 모드에서 `<Space>`대신 `=`를 입력하면, 아래와 같이 `=`로 정렬된다.

```
apple  = red
grass += green
sky   -= blue
```

#### `**` 사용

easy-align `**=`를 입력하면, 아래와 같이 `=`로 좌우 정렬이 바뀐다.

```
apple  =   red
grass += green
sky   -=  blue
```

더 자세한 내용은 플러그인 사이트 참고
https://github.com/junegunn/vim-easy-align

### emmet

새로운 파일을 열고
입력 모드로 전환해서 아래 내용을 입력

```
html:5
```

입력 모드 상태에서 ctrl+y와 콤마를 입력

```
<c-y>,   (Ctrl+y누른후 콤마를 입력, 콤마 입력시 Ctrl은 눌리지 않은 상태)
```

그러면 아래와 같이 나옴

```html
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="UTF-8" />
    <title></title>
  </head>
  <body></body>
</html>
```

입력모드에서 커서가 줄 끝의 div뒤에 있게 하고

```
div>div>div
```

이 상태에서 ctrl+y, 입력하면 아래와 같이 됨

```html
<div>
  <div>
    <div></div>
  </div>
</div>
```

이 외에도 emet-vim의 유용한 기능이 많이 있음, 아래 글을 참조

> https://raw.githubusercontent.com/mattn/emmet-vim/master/TUTORIAL

### vim-surround

- ysiw]

```
Hello world

(명령모드) ysiw]

[Hello] world
```

- ysiw[

```
Hello world

(명령모드) ysiw[

[ Hello ] world  => 공백이 포함됨
```

- yss)

```
Hello world

(명령모드) yss)

(Hello world)
```

- yss(

```
Hello world

(명령모드) yss(

( Hello world )  => 공백이 포함됨
```

- ds

```
( Hello world )

(명령모드) ds(

Hello world  => 앞뒤 공백이 제거됨
```

```
( Hello world )

(명령모드) ds(

 Hello world   => 앞뒤 공백이 유지됨
```

- cs

```
"Hello"

(명령모드) cs"'

'Hello'
```

```
'Hello'

(명령모드) cs'"

"Hello"
```

```
[Hello] world

(명령모드) cs]{  =>  cs[{ 도 결과는 동일, 즉 괄호의 방향은 상관없음

{Hello} world
```

- cst 태그를 바꾸기

```
<div>Hello</div>

(명령모드) cst"

"Hello"
```

```
"Hello"

(명령모드) cs"<p>

<p>Hello</p>
```

```
<div>Hello</div>

(명령모드) cst}

{Hello}
```

```
<div>Hello</div>

(명령모드) cst{

{ Hello }
```

- 비주얼 모드에서 사용

```
<em>Hello</em>

(명령모드) V (대문자 V)를 누르면 한줄이 모두 선택됨, 여러 줄을 선택한 후
S(대문자S)를 누르고 <div> 입력(대문자 S는 Sorround 기능이구나)

<div>
<em>Hello</em>
</div>

```

### dir-configs-override

이 플러그인은 프로젝트마다 vim 설정을 다르게 하고 싶을때 사용할 수 있다.
프로젝트 폴더에 .vim.custom 파일을 만들어서 .vimrc에 넣을 만한 내용들을 넣으면 된다.
Example

---

Suppose you have:

    home
    └── user
        ├── projects
        │   ├── fades
        │   ├── fisa-vim-config
        │   ├── other-python-project
        │   │   └── .vim.custom
        │   └── .vim.custom
        └── .vim.custom

Where the contents of every `.vim.custom` is:

    $ cat home/user/.vim.custom
    let g:syntastic_python_flake8_args = "--max-line-length=100"
    let foo = "bar"


    $ cat home/user/projects/.vim.custom
    let foo = "bar in project"


    $ cat home/user/projects/other-python-project/.vim.custom
    let g:syntastic_python_flake8_args = "--max-line-length=80"

If Vim is opened in _/home/user/projects/other-python-project/_, configs wil be:

- foo = "bar"
- syntastic_python_flake8_args = "--max-line-length=80"

### choosewin

vim내에서 여러 개의 창을 열었을때 창을 쉽게 선택하게 해준다.
`-`기호로 키를 매핑하고 사용한다.

### ack

vim에서 grep을 실행하는 플러그인이다. 아래 명령은 현재 폴더의 하위 폴더에서 foo 문자열 포함한 파일을 찾는다.

아래 문서에 잘 설명하고 있다.
https://nolboo.kim/blog/2017/01/16/practical-vim/

> 우분투에서는 ack-grep 명령을 설치해야 한다.

```bash
# ubuntu
$ sudo apt-get install ack-grep

# mac
$ brew install ack
```

```
:Ack foo
```

### CtrlP

파일 찾기 플러그인, 아래 문서 참고

https://github.com/kien/ctrlp.vim

`:CtrlP` 입력하면 파일목록이 나온다.
서브 디렉토리의 파일도 나오고, 쉽게 필터링해서 파일을 찾을 수 있다.

```vim
:CtrlP
```

### vim-better-whitespace

줄끝 공백을 시각적으로 표시하거나 감추기, 줄끝 공백을 지울 수 있다.

https://github.com/ntpeters/vim-better-whitespace

```vim
:EnableWhitespace
:DisableWhitespace
:ToggleWhitespace
```

```vim
:StripWhitespace
```
