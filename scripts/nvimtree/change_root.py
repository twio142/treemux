#!/use/bin/env python3

import sys

import pynvim

lua_code = """
nt_api.tree.change_root('{rootdir}')
"""

nvim_addr = sys.argv[1]
new_root = sys.argv[2]

nvim = pynvim.attach('socket', path=nvim_addr)
nvim.exec_lua(lua_code.format(rootdir=new_root))
