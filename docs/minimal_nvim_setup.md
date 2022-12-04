# I don't use Neovim. I use vim/emacs/vscode etc. Can I still use your plugin?

Here's the minimal setup guide for those who don't want to learn how vim plugins work.

1. Install Neovim

2. Put this init.vim into `~/.config/nvim/init.vim`

```nvim
# Neovim init.vim

set⋅runtimepath^=~/.vim⋅runtimepath+=~/.vim/after
let⋅&packpath⋅=⋅&runtimepath

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
	  sort_by = "case_sensitive",
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
	  filters = {
		  dotfiles = true,
	  },
	  remove_keymaps = {
		  '-',
	  }
	})
EOF

colorscheme tokyonight-night
set cursorline
```

3. Run `nvim`. It will install plugins automatically.
4. Run `nvim .` to see the current directory with Nvim-Tree
