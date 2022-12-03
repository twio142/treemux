# Tmux Side-Nvim-Tree

`tmux-side-nvim-tree` opens a sidebar with Neovim's [Nvim-Tree](https://github.com/nvim-tree/nvim-tree) file explorer,  
With additional cool features like:

- Automatic updates on Nvim-Tree as you change directory in shell.
- Nvim-Tree to shell interaction possible with [tmuxpaste.vim](https://github.com/kiyoon/tmuxpaste.vim).
  - You can copy absolute path from Nvim-Tree and paste into the shell.
  - Change directory, execute programs, open with vim and anything you can imagine!

![screenshot](/screenshot.gif)

Of course you also get:

- All features from Nvim-Tree: mouse click, automatic refresh, file icons etc.
- All features from tmux-sidebar:
	- **smart sizing**<br/>
	  Sidebar remembers its size, so the next time you open it, it will have the
	  **exact same** width. This is a per-directory property, so you can have just
	  the right size for multiple dirs.
	- **toggling**<br/>
	  The same key binding opens and closes the sidebar.
	- **uninterrupted workflow**<br/>
	  The main `prefix + Tab` key binding opens a sidebar but **does not** move
	  cursor to it.
	- **pane layout stays the same**<br/>
	  No matter which pane layout you prefer, sidebar tries hard not to mess your
	  pane splits. Open, then close the sidebar and everything should look the same.


Nothing has been this close to IDE!

Tested and working on Linux, and Windows WSL2.

### Key bindings

- `prefix + Tab` - toggle sidebar with a directory tree
- `prefix + Backspace` - toggle sidebar and move cursor to it (focus it)

### Installation with [Tmux Plugin Manager](https://github.com/tmux-plugins/tpm) (recommended)

Add plugin to the list of TPM plugins in `.tmux.conf`:

    set -g @plugin 'kiyoon/tmux-side-nvim-tree'

Hit `prefix + I` to fetch the plugin and source it. You should now be able to
use the plugin.

### Docs

- [customization options](docs/options.md)

### License

[MIT](LICENSE.md)
