set fencs=ucs-bom,utf-8,cp949
set ts=4
set shiftwidth=4
set cindent
set smartindent
set autoindent
set nowrap
set ff=unix
set bg=dark
set ruler
set statusline=%h%F%m%r%=[%l:%c(%p%%)] " 상태표시줄 포맷팅
set number

let using_neovim = has('nvim')
let using_vim = !using_neovim

" ============================================================================
" Vim-plug initialization
" Avoid modifying this section, unless you are very sure of what you are doing

let vim_plug_just_installed = 0
if using_neovim
    let vim_plug_path = expand('~/.config/nvim/autoload/plug.vim')
else
    let vim_plug_path = expand('~/.vim/autoload/plug.vim')
endif
if !filereadable(vim_plug_path)
    echo "Installing Vim-plug..."
    echo ""
    if using_neovim
        silent !mkdir -p ~/.config/nvim/autoload
        silent !curl -fLo ~/.config/nvim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    else
        silent !mkdir -p ~/.vim/autoload
        silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    endif
    let vim_plug_just_installed = 1
endif

" manually load vim-plug the first time
if vim_plug_just_installed
    :execute 'source '.fnameescape(vim_plug_path)
endif

" this needs to be here, so vim-plug knows we are declaring the plugins we
" want to use
if using_neovim
    call plug#begin("~/.config/nvim/plugged")
else
    call plug#begin("~/.vim/plugged")
endif

map <F1> v]}zf
map <F2> zo
map <F3> :30vs .<CR>

map <F9> :%s/[ <Tab>]*$//g

map <F10> :PlugInstall<CR><C-W><C-W>

" HEXA VIEW ON
map <F11> :%!xxd<CR>
" HEXA VIEW OFF
map <F12> :%!xxd -r<CR>

map <PageDown> <C-w>+
map <PageUp> <C-w>-
map <C-Right> <C-w>>
map <C-Left> <C-w><

" ==== vim-eash-plugins ====
" Start interactive EasyAlign in visual mode (e.g. vipga)
xmap ga <Plug>(EasyAlign)

" Start interactive EasyAlign for a motion/text object (e.g. gaip)
nmap ga <Plug>(EasyAlign)

" ========= 인덴트 설정해제 ===============
map ,ni :set noai<CR>:set nocindent<CR>:set nosmartindent<CR>
map ,si :set ai<CR> cindent<CR>:set smartindent<CR>

map ; :Files<CR>
map <C-o> :NERDTreeToggle<CR>

set laststatus=2

let g:lightline = {
	\ 'colorscheme': 'wombat',
	\ 'active': {
	\     'left': [['mode', 'paste' ], ['readonly', 'filename', 'modified']],
	\      'right': [['lineinfo'], ['percent'], ['fileformat', 'fileencoding']]
	\ },
	\ }


" 파란색 글자는 잘 안보인다
highlight Comment term=none cterm=none gui=none ctermfg=LightGray


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
Plug 'tpope/vim-eunuch'
Plug 'tpope/vim-surround'
Plug 'chr4/nginx.vim'

" Plug 'w0rp/ale'
" Plug 'airblade/vim-gitgutter'
" Plug 'vim-scripts/taglist.vim'

call plug#end()

autocmd FileType yaml setlocal ts=2 sts=2 sw=2 expandtab

set fencs=ucs-bom,utf-8,cp949
set ts=4
set shiftwidth=4
set cindent
set smartindent
set autoindent
set nowrap
set ff=unix
set bg=dark
set ruler
set statusline=%h%F%m%r%=[%l:%c(%p%%)] " 상태표시줄 포맷팅
set number