#!/use/bin/env python3

import sys
import time

try:
    import pynvim
except ImportError as e:
    print("pynvim not installed")
    print(e)
    sys.exit(50)

lua_code = """
local initial_root_dir = nt_api.tree.get_nodes().absolute_path

if initial_root_dir ~= '{main_pane_cwd}' then
    nt_api.tree.find_file('{main_pane_cwd}')
    local nt_node = nt_api.tree.get_node_under_cursor()

    folder_found = true
    if nt_node ~= nil then
        if nt_node.absolute_path ~= '{main_pane_cwd}' then
            nt_api.tree.change_root('{side_pane_root}')
            nt_api.tree.find_file('{main_pane_cwd}')
            local nt_node = nt_api.tree.get_node_under_cursor()
            if nt_node.absolute_path ~= '{main_pane_cwd}' then
                folder_found = false
                nt_api.tree.change_root('{main_pane_cwd}')
            end
        end

        if folder_found then
            if not nt_node.open then
                nt_api.node.open.edit()
            end

            if (vim.fn.winline() / vim.fn.winheight(0)) > 0.5 then
                vim.cmd('normal! zz')
            end
        end
    end
end
"""

nvim_addr = sys.argv[1]
main_pane_cwd = sys.argv[2]
side_pane_root = sys.argv[3]

for _ in range(1000):
    try:
        nvim = pynvim.attach("socket", path=nvim_addr)
    except Exception as e:
        time.sleep(0.1)
    else:
        break
else:
    print("Timeout while waiting for nvim to start")
    sys.exit(51)

# Wait until Nvim-Tree is running
filetype = ""
for _ in range(1000):
    filetype = nvim.eval("&filetype")
    if filetype == "NvimTree":
        break
    time.sleep(0.1)
else:
    print(f"Timeout while waiting for Nvim-Tree to start. Filetype is: {filetype}")
    sys.exit(52)

# If side pane root manually configured, we need to open the cwd.
nvim.exec_lua("nt_api = require('nvim-tree.api')")
nvim.exec_lua(
    lua_code.format(main_pane_cwd=main_pane_cwd, side_pane_root=side_pane_root)
)
print(
    nvim.exec_lua("return nt_api.tree.get_nodes().absolute_path")
)  # print new root dir
