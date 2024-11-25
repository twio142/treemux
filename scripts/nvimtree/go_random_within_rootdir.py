#!/use/bin/env python3

import sys

import pynvim

lua_code = """
local target_path = vim.fn.split(vim.fn.expand('{target_path}/*'), '\\n')[1]
if #target_path > 0 then
    require('neo-tree.command').execute({{
        action = "focus",
        reveal_file = target_path,
        reveal_force_cwd = true,
    }})
end
require('neo-tree.command').execute({{
    action = "focus",
    reveal_file = vim.fn.expand('{target_path}'),
}})
"""

nvim_addr = sys.argv[1]
main_pane_cwd = sys.argv[2]
side_pane_root = sys.argv[3]

nvim = pynvim.attach('socket', path=nvim_addr)
nvim.exec_lua(lua_code.format(target_path=main_pane_cwd))
print(side_pane_root)  # return root dir
