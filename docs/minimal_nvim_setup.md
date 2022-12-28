# I don't use Neovim. I use vim/emacs/vscode etc. Can I still use your plugin?

Here's the minimal setup guide for those who don't want to learn how vim plugins work.

1. Install Neovim

2. Put this init.vim into `~/.config/nvim/init.vim`

```nvim
" Neovim init.vim

set runtimepath^=~/.vim runtimepath+=~/.vim/after
let &packpath = &runtimepath

" Remove the white status bar below
set laststatus=0 ruler

" True colour support
set termguicolors

" Automatic installation of vim-plug
let data_dir = has('nvim') ? stdpath('data') . '/site' : '~/.vim'
if empty(glob(data_dir . '/autoload/plug.vim'))
  silent execute '!curl -fLo '.data_dir.'/autoload/plug.vim --create-dirs  https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
  autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
endif

" Run PlugInstall if there are missing plugins
autocmd VimEnter * if len(filter(values(g:plugs), '!isdirectory(v:val.dir)'))
  \| PlugInstall --sync | source $MYVIMRC
\| endif

call plug#begin()

Plug 'kiyoon/tmuxsend.vim'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'nvim-tree/nvim-web-devicons' " optional, for file icons
Plug 'nvim-tree/nvim-tree.lua'

call plug#end()

lua << EOF
require("nvim-tree").setup({
view = {
	adaptive_size = true,
	mappings = {
		list = {
			{ key = "u", action = "dir_up" },
		},
	},
	},
renderer = {
	group_empty = true,
},
remove_keymaps = {
	'-',
}
})
EOF

colorscheme tokyonight-night
set cursorline

" tmuxsend.vim
nnoremap <silent> - <Plug>(tmuxsend-smart)	" `1-` sends a line to pane .1
xnoremap <silent> - <Plug>(tmuxsend-smart)	" same, but for visual mode block
nnoremap <silent> _ <Plug>(tmuxsend-plain)	" `1_` sends a line to pane .1 without adding a new line
xnoremap <silent> _ <Plug>(tmuxsend-plain)
nnoremap <silent> <space>- <Plug>(tmuxsend-uid-smart)	" `3<space>-` sends to pane %3
xnoremap <silent> <space>- <Plug>(tmuxsend-uid-smart)
nnoremap <silent> <space>_ <Plug>(tmuxsend-uid-plain)
xnoremap <silent> <space>_ <Plug>(tmuxsend-uid-plain)
nnoremap <silent> <C-_> <Plug>(tmuxsend-tmuxbuffer)		" `<C-_>` yanks to tmux buffer
xnoremap <silent> <C-_> <Plug>(tmuxsend-tmuxbuffer)
```

3. Run `nvim` which will install plugins automatically. Then `:q` to exit.
4. Run `nvim .` to see the current directory with Nvim-Tree
