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
Plug 'kiyoon/nvim-tree-remote.nvim'
Plug 'folke/tokyonight.nvim', { 'branch': 'main' }
Plug 'nvim-tree/nvim-web-devicons'
Plug 'nvim-tree/nvim-tree.lua'
Plug 'aserowy/tmux.nvim'

call plug#end()

lua << EOF
local nvim_tree = require('nvim-tree')
local nt_remote = require('nvim_tree_remote')

nvim_tree.setup {
  update_focused_file = {
    enable = true,
    update_cwd = true,
  },
  renderer = {
    --root_folder_modifier = ":t",
    icons = {
      glyphs = {
        default = "",
        symlink = "",
        folder = {
        arrow_open = "",
        arrow_closed = "",
        default = "",
        open = "",
        empty = "",
        empty_open = "",
        symlink = "",
        symlink_open = "",
        },
        git = {
        unstaged = "",
        staged = "S",
        unmerged = "",
        renamed = "➜",
        untracked = "U",
        deleted = "",
        ignored = "◌",
        },
      },
    },
  },
  diagnostics = {
    enable = true,
    show_on_dirs = true,
    icons = {
    hint = "",
    info = "",
    warning = "",
    error = "",
    },
  },
  view = {
    width = 30,
    side = "left",
    mappings = {
      list = {
        { key = "u", action = "dir_up" },
        { key = "<F1>", action = "toggle_file_info" },
        { key = { "l", "<CR>", "<C-t>", "<2-LeftMouse>" }, action = "remote_tabnew", action_cb = nt_remote.tabnew },
        { key = "h", action = "close_node" },
        { key = { "v", "<C-v>" }, action = "remote_vsplit", action_cb = nt_remote.vsplit },
        { key = "<C-x>", action = "remote_split", action_cb = nt_remote.split },
        { key = "o", action = "remote_tabnew_main_pane", action_cb = nt_remote.tabnew_main_pane },
      },
    },
  },
  remove_keymaps = {
    '-',
    '<C-k>',
    'O',
  },
  filters = {
    custom = { ".git" },
  },
}
EOF

" Navigate tmux, and nvim splits.
" Sync nvim buffer with tmux buffer.
lua require("tmux").setup({ copy_sync = { enable = true, sync_clipboard = false, sync_registers = true }, resize = { enable_default_keybindings = false } })

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
