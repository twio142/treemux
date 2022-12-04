## Options

Customize `tmux-side-nvim-tree` by placing options in `.tmux.conf` and reloading Tmux
environment.

> Can I change the refresh rate? (default: 0.5)

    set -g @sidenvimtree-refresh-interval '0.1'

> Can I have the sidebar on the right?

    set -g @sidenvimtree-tree-position 'right'

> I don't like the default 'prefix + Tab' key binding. Can I change it to be
'prefix + e'?

    set -g @sidenvimtree-tree 'e'

> How can I change the default 'prefix + Backspace' to be 'prefix + w'?

    set -g @sidenvimtree-tree-focus 'w'

> The default sidebar width is 40 columns. I want the sidebar to be wider by
default!

    set -g @sidenvimtree-tree-width '60'

> Specify Neovim path (default: `nvim`)

    set -g @sidenvimtree-nvim-command '/path/to/nvim'

> Specify Python path (default: `python3`)

    set -g @sidenvimtree-python-command '/path/to/python3'

> Dev debug mode which will open another pane for debugging.

    set -g @sidenvimtree-enable-debug-pane '1'
