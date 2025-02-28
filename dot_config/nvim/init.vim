" Plugins will be downloaded under the specified directory.
" call plug#begin(has('nvim') ? stdpath('data') . '/plugged' : '~/.vim/plugged')
call plug#begin('~/.local/share/nvim/site/plugged')

" Declare the list of plugins.
Plug 'tpope/vim-sensible'               " Sensible defaults
Plug 'vim-airline/vim-airline'          " Status line
Plug 'vim-airline/vim-airline-themes'   " Themes for airline
Plug 'junegunn/vim-easy-align'          " Easy alignment

" Visual Settings
Plug 'junegunn/goyo.vim'
Plug 'junegunn/limelight.vim'

Plug 'preservim/nerdtree', { 'on': 'NERDTreeToggle' }

" Color theme plugins
Plug 'junegunn/seoul256.vim'
Plug 'joshdick/onedark.vim'

" fzf
Plug 'vijaymarupudi/nvim-fzf'
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

" Git integration
Plug 'airblade/vim-gitgutter' " Git diff in the gutter

" List ends here. Plugins become visible to Vim after this call.
call plug#end()

"""""""""""""""""""""""""""""""""""""""""""""""""
" Color Settings
"""""""""""""""""""""""""""""""""""""""""""""""""
syntax on
colorscheme onedark

"""""""""""""""""""""""""""""""""""""""""""""""""
" Visual Settings
"""""""""""""""""""""""""""""""""""""""""""""""""
" For Goyo
" Configure Goyo to not center content
let g:goyo_width = '100%' " Use full width
let g:goyo_height = '100%' " Use full height

" For LimeLight
" Color name (:help cterm-colors) or ANSI code
let g:limelight_conceal_ctermfg = 'gray'
let g:limelight_conceal_ctermfg = 240
" Color name (:help gui-colors) or RGB color
let g:limelight_conceal_guifg = 'DarkGray'
let g:limelight_conceal_guifg = '#777777'
" highlight line
let g:limelight_bop = '^.*$'
" let g:limelight_eop = '\n'
let g:limelight_paragraph_span = 0

"""""""""""""""""""""""""""""""""""""""""""""""""
" UI Settings
"""""""""""""""""""""""""""""""""""""""""""""""""
" Keep cursor in the middle of the page, useful for editing text
" set so=999
" Enable relative line numbers
set number
set relativenumber

" Highlight the current line
set cursorline

" Enable mouse support
set mouse=a

" Set tab width to 4 spaces
set tabstop=4
set shiftwidth=4
set expandtab

" Enable auto-indentation
set autoindent

" Show matching brackets
set showmatch

" Highlight search results
set hlsearch

" Incremental search (search as you type)
set incsearch

" Ignore case when searching
set ignorecase

" Smart case sensitivity when searching
set smartcase

" Enable backspace over autoindent, line breaks, and start of insert
set backspace=indent,eol,start

" Enable persistent undo
set undofile
set undodir=~/.local/share/nvim/undodir

" Create the undodir if it doesn't exist
if !isdirectory(&undodir)
    call mkdir(&undodir, "p", 0700)
endif

" Enable spell checking for Git commit messages
autocmd FileType gitcommit setlocal spell

" Automatically wrap text at 72 characters for Git commit messages
autocmd FileType gitcommit setlocal textwidth=72

" Enable status line
set laststatus=2

" Show the mode you're in (e.g., INSERT, VISUAL)
set showmode

" Enable clipboard integration (requires Neovim with +clipboard feature)
set clipboard=unnamedplus

"""""""""""""""""""""""""""""""""""""""""""""""""
" Plugin Settings
"""""""""""""""""""""""""""""""""""""""""""""""""
" Configure vim-airline
let g:airline_theme = 'onedark' " Match your theme
let g:airline#extensions#tabline#enabled = 1

" Configure NERDTree
map <C-n> :NERDTreeToggle<CR>

" Configure vim-gitgutter
let g:gitgutter_enabled = 1
let g:gitgutter_signs = 1
let g:gitgutter_highlight_lines = 1

" Configure fzf
let g:fzf_layout = { 'down': '40%' }
nnoremap <C-p> :Files<CR>
nnoremap <C-f> :Rg<CR>

"""""""""""""""""""""""""""""""""""""""""""""""""
" Custom Keybindings
"""""""""""""""""""""""""""""""""""""""""""""""""
" Toggle Goyo and Limelight together
nnoremap <leader>g :Goyo<CR>:Limelight!!<CR>

" Toggle relative line numbers
nnoremap <leader>r :set relativenumber!<CR>
" Turn limelight on by default
autocmd VimEnter * Limelight
autocmd VimEnter * AirlineToggle
" Turn Goyo on with key remap
nnoremap <leader>g :Goyo<CR>:Limelight!!<CR>
" Turn Goyo on by default
" autocmd VimEnter * Goyo
" In Goyo, if airline is turned on, do nto show scratch area
"autocmd! User GoyoEnter nested set eventignore=FocusGained
"autocmd! User GoyoLeave nested set eventignore=
