#!/usr/bin/env python3
import sys
import pynvim

nvim_addr = sys.argv[1]
new_root = sys.argv[2]

nvim = pynvim.attach('socket', path=nvim_addr)
nvim.command(f"e {new_root}")
