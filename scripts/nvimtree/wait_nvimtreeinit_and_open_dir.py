#!/usr/bin/env python3

import sys
import time

try:
    import pynvim
except ImportError as e:
    print("pynvim not installed")
    print(e)
    sys.exit(50)

lua_code = """
local cwd = vim.fn.getcwd()
if cwd ~= '{main_pane_cwd}' then
    require('neo-tree.command').execute({{
        action = "focus",
        reveal_file = vim.fn.expand('{main_pane_cwd}'),
        position = "current",
        reveal_force_cwd = true,
    }})
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

# Wait until neo-tree is running
filetype = ""
for _ in range(1000):
    filetype = nvim.eval("&filetype")
    if filetype == "neo-tree":
        break
    time.sleep(0.1)
else:
    print(f"Timeout while waiting for neo-tree to start. Filetype is: {filetype}")
    sys.exit(52)

# If side pane root manually configured, we need to open the cwd.
nvim.exec_lua(
    lua_code.format(main_pane_cwd=main_pane_cwd)
)
print(nvim.eval("getcwd()"))  # print current working directory
