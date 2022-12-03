#!/use/bin/env python3

import sys

import pynvim

lua_code = """
nt_api = require('nvim-tree.api')
nt_api.tree.find_file('{main_pane_first_child}')
local nt_node = nt_api.tree.get_node_under_cursor()

folder_found = true
if nt_node ~= nil then
  if nt_node.absolute_path ~= '{main_pane_first_child}' then
    nt_api.tree.change_root('{side_pane_root}')
    nt_api.tree.find_file('{main_pane_first_child}')
    local nt_node = nt_api.tree.get_node_under_cursor()
    if nt_node.absolute_path ~= '{main_pane_first_child}' then
      folder_found = false
      print('Folder not found in nvim-tree. Is it hidden?')
      nt_api.tree.change_root('{main_pane_first_child}')
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
"""

nvim_addr = sys.argv[1]
main_pane_first_child = sys.argv[2]     # directory to close. It is the first child of the directory you're going into.
side_pane_root = sys.argv[3]            # In case the root has been modified manually, go back to the original root.

nvim = pynvim.attach('socket', path=nvim_addr)
nvim.exec_lua(lua_code.format(main_pane_first_child=main_pane_first_child, side_pane_root=side_pane_root))
print(nvim.exec_lua('return nt_api.tree.get_nodes().absolute_path'))    # print new root dir
