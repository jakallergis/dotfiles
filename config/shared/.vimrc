set nocompatible

" Leader - ( Spacebar )
let mapleader = " "

" Use qq in insert and command mode to Esc and to exit when in normal mode
inoremap qq <Esc>
cnoremap qq <Esc> 
nnoremap qq :q<cr>
nnoremap q1 :q!<cr>

" Use qs to save while in insert mode
inoremap qs <Esc>:w<cr>a

" Use space-s to refresh
nnoremap <leader>s :so $MYVIMRC<cr>

" Use space-w to save
nnoremap <leader>w :w<cr>

" Use enter to create new line w/o entering insert mode
nnoremap <CR> o <Esc>k

" Use Syntax
syntax on

" Handle Lining
set number
set relativenumber
set numberwidth=5

" Handle Cursor
set cursorline 
set nostartofline
set ruler

" Enable Status Bar
set laststatus=2

" Searching
set gdefault
set ignorecase
set smartcase
set showmatch
set hlsearch
set incsearch
" Use qd to toggle search highlight
nnoremap qd :set hlsearch!<cr>
inoremap qd <Esc>:set hlsearch!<cr>a

" Softtabs 2 spaces
set autoindent
set smartindent
set smarttab
set softtabstop=2
set tabstop=2
set shiftwidth=2
set shiftround
set expandtab
filetype plugin on
filetype indent on

" Display tabs and trailing spaces visually
set list listchars=tab:\ \ ,trail:·
set linebreak

" HTML Syntax
set matchpairs+=<:>

" Treat <li> and <p> tags like the block tags they are
let g:html_intent_tags = 'li\|p'

" Allow stylesheets to autocomplete hyphenated words
autocmd FIleType css,scss,sass,less setlocal iskeyword+=-
