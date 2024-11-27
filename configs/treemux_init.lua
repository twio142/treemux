-- Neovim init.lua
vim.g.loaded_netrw = 1
vim.g.loaded_netrwPlugin = 1

-- Remove the white status bar below
vim.o.laststatus = 0

-- True colour support
vim.o.termguicolors = true

-- lazy.nvim plugin manager
local lazypath = vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system {
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", -- latest stable release
    lazypath,
  }
end
vim.opt.rtp:prepend(lazypath)

local function escape(str)
  return '"' .. vim.fn.escape(str, '"!$\\`') .. '"'
end

require("lazy").setup {
  "folke/tokyonight.nvim",
  {
    "nvim-neo-tree/neo-tree.nvim",
    version = "*",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "nvim-tree/nvim-web-devicons",
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("neo-tree").setup {
        sources = {
          "filesystem",
        },
        source_selector = {
          sources = {
            { source = "filesystem" },
          },
        },
        close_if_last_window = true,
        enable_git_status = true,
        enable_diagnostics = false,
        sort_case_insensitive = false,
        sort_function = nil,
        default_component_configs = {
          container = {
            enable_character_fade = false,
          },
          indent = {
            indent_size = 2,
            padding = 0,
            with_markers = true,
            indent_marker = "│",
            last_indent_marker = "└",
            highlight = "NeoTreeIndentMarker",
            with_expanders = nil,
            expander_collapsed = "",
            expander_expanded = "",
            expander_highlight = "NeoTreeExpander",
          },
          icon = {
            folder_closed = "",
            folder_open = "󰝰",
            folder_empty = "",
            default = "*",
            highlight = "NeoTreeFileIcon",
          },
          modified = {
            symbol = "[+]",
            highlight = "NeoTreeModified",
          },
          name = {
            trailing_slash = false,
            use_git_status_colors = true,
            highlight = "NeoTreeFileName",
          },
          git_status = {
            symbols = {
              added = "",
              modified = "",
              deleted = "✖",
              renamed = "󰁕",
              untracked = "",
              ignored = "",
              unstaged = "*",
              staged = "󰐕",
              conflict = "",
            },
          },
          file_size = {
            enabled = true,
            required_width = 64,
          },
          type = {
            enabled = true,
            required_width = 122,
          },
          last_modified = {
            enabled = true,
            required_width = 88,
          },
          created = {
            enabled = true,
            required_width = 110,
          },
          symlink_target = {
            enabled = true,
          },
        },
        commands = {
          toggle_open = function(state)
            local cmd = require "neo-tree.sources.common.commands"
            local node = state.tree:get_node()
            if node:has_children() then
              cmd.toggle_node(state)
            elseif node.type == "directory" then
              require("neo-tree.sources.filesystem").toggle_directory(state)
            else
              require("neo-tree").config.commands.open_in_tmux(state)
            end
          end,
          open_in_tmux = function(state, target)
            local node = state.tree:get_node()
            if target == "t" then
              local cmd = { "tmux", "new-window" }
              if node.type == "file" then
                table.insert(cmd, "nvim " .. escape(node.path))
              else
                table.insert(cmd, "-c")
                table.insert(cmd, node.path)
              end
              vim.fn.jobstart(cmd)
              return
            end
            local pane = "{last}"
            if not target then
              local p = vim.fn.system "tmux display -p '#{pane_index}'"
              if vim.v.count > 0 and vim.v.count ~= tonumber(p) then
                pane = tostring(vim.v.count)
              end
            end
            if target == "s" or target == "v" then
              vim.fn.jobstart { "tmux", "selectp", "-t", pane }
              local cmd = { "tmux", "splitw" }
              if target == "s" then
                table.insert(cmd, "-v")
              else
                table.insert(cmd, "-h")
              end
              if node.type == "file" then
                table.insert(cmd, "nvim " .. escape(node.path))
              else
                table.insert(cmd, "-c")
                table.insert(cmd, node.path)
              end
              vim.fn.jobstart(cmd)
              return
            end
            local result = vim.fn.system('tmux display -p -t "' .. pane .. '" "#{pane_current_command} #{pane_pid}"')
            vim.fn.jobstart { "tmux", "selectp", "-t", pane }
            local proc, pid = result:match "^(%S+) (%d+)"
            if node.type == "file" then
              if proc == "nvim" then
                local command = "pid="
                  .. pid
                  .. [[;
                until (ps -o command= -p $pid | grep -Eq "^nvim --embed"); do
                  pid=$(pgrep -P $pid 2> /dev/null)
                  [ -z "$pid" ] && exit
                done
                command -v nvr &> /dev/null && nvr --serverlist || find $TMPDIR --type s 2>/dev/null | grep $pid ]]
                local socket = vim.fn.trim(vim.fn.system(command))
                if socket ~= "" then
                  vim.fn.jobstart { "nvim", "--server", socket, "--remote", node.path }
                  return
                end
              elseif proc == "zsh" then
                vim.fn.jobstart { "tmux", "send", "nvim " .. escape(node.path), "Enter" }
              else
                vim.fn.jobstart { "tmux", "splitw", "-v", "nvim " .. escape(node.path), "Enter" }
              end
            else
              if proc == "zsh" then
                vim.fn.jobstart { "tmux", "send", "cd " .. escape(node.path), "Enter" }
              else
                vim.fn.jobstart { "tmux", "splitw", "-v", "-c", node.path }
              end
            end
          end,
          send_to_tmux = function(state, run)
            local tx = { "tmux", "selectp", "-t" }
            local mode = vim.api.nvim_get_mode().mode
            local text
            if mode == "n" then
              text = state.tree:get_node().path
            else
              vim.cmd "normal! y"
              text = vim.fn.getreg '"'
            end
            local chan = vim.fn.jobstart({ "tmux", "loadb", "-" }, { stdin = "pipe" })
            vim.fn.chansend(chan, text)
            vim.fn.chanclose(chan, "stdin")
            local p = vim.fn.system "tmux display -p '#{pane_index}'"
            if vim.v.count > 0 and vim.v.count ~= tonumber(p) then
              table.insert(tx, tostring(vim.v.count))
            else
              table.insert(tx, "{last}")
            end
            vim.list_extend(tx, { ";", "pasteb", "-d" })
            if run then
              vim.list_extend(tx, { ";", "send", "Enter", ";", "selectp", "-l" })
            end
            vim.fn.jobstart(tx)
          end,
        },
        window = {
          position = "current",
          width = "100%",
          mapping_options = {
            noremap = true,
            nowait = true,
          },
          mappings = {
            ["oc"] = "",
            ["od"] = "",
            ["og"] = "",
            ["om"] = "",
            ["on"] = "",
            ["os"] = "",
            ["ot"] = "",
            ["w"] = "",
            ["o"] = {
              "open_in_tmux",
              noremap = false,
              nowait = true,
            },
            ["O"] = {
              function(state)
                local path = state.tree:get_node().path
                vim.ui.open(path)
              end,
              desc = "system_open",
            },
            ["<2-LeftMouse>"] = "open_in_tmux",
            ["l"] = "toggle_open",
            ["<esc>"] = "cancel",
            ["<tab>"] = {
              function(state)
                local node = state.tree:get_node()
                vim.fn.jobstart { "qlmanage", "-p", node.path }
              end,
            },
            ["<C-s>"] = {
              function(state)
                require("neo-tree").config.commands.open_in_tmux(state, "s")
              end,
              desc = "open_in_split",
            },
            ["<C-v>"] = {
              function(state)
                require("neo-tree").config.commands.open_in_tmux(state, "v")
              end,
              desc = "open_in_vsplit",
            },
            ["s"] = "",
            ["<C-t>"] = {
              function(state)
                require("neo-tree").config.commands.open_in_tmux(state, "t")
              end,
              desc = "open_in_new_window",
            },
            ["<space>"] = "",
            -- ['<cr>'] = 'open_drop',
            -- ['t'] = 'open_tab_drop',
            ["P"] = "show_preview",
            ["h"] = {
              function(state)
                local node = state.tree:get_node()
                require("neo-tree.ui.renderer").focus_node(state, node:get_parent_id(), true)
              end,
              desc = "find_parent",
            },
            ["H"] = "close_node",
            ["J"] = {
              function(state)
                local node = state.tree:get_node()
                local siblings = state.tree:get_nodes(node:get_parent_id())
                for i, v in ipairs(siblings) do
                  if v.name == node.name then
                    local next_node = siblings[i + 1] or siblings[1]
                    require("neo-tree.ui.renderer").focus_node(state, next_node:get_id(), true)
                    return
                  end
                end
              end,
              desc = "next_sibling",
            },
            ["K"] = {
              function(state)
                local node = state.tree:get_node()
                local siblings = state.tree:get_nodes(node:get_parent_id())
                for i, v in ipairs(siblings) do
                  if v.name == node.name then
                    local next_node = siblings[i - 1] or siblings[#siblings]
                    require("neo-tree.ui.renderer").focus_node(state, next_node:get_id(), true)
                    return
                  end
                end
              end,
              desc = "previous_sibling",
            },
            ["{"] = "close_all_nodes",
            ["}"] = "expand_all_nodes",
            ["N"] = {
              "add",
              config = {
                show_path = "none",
              },
            },
            ["d"] = "delete",
            ["r"] = "rename",
            ["x"] = "cut_to_clipboard",
            ["p"] = "paste_from_clipboard",
            ["c"] = "copy",
            ["C"] = "copy_to_clipboard",
            ["m"] = "move",
            ["q"] = function()
              vim.cmd "quitall!"
            end,
            ["R"] = "refresh",
            ["?"] = "show_help",
            ["I"] = "show_file_details",
            ["<C-u>"] = "",
            ["<C-d>"] = "",
            ["y"] = {
              function(state)
                local path = state.tree:get_node().path
                vim.fn.setreg("*", path)
                vim.notify("Yanked path to clipboard: " .. path)
              end,
              desc = "yank file path",
            },
            ["\\y"] = {
              function(state)
                local path = state.tree:get_node().path
                local chan = vim.fn.jobstart({ "tmux", "loadb", "-" }, { stdin = "pipe" })
                vim.fn.chansend(chan, path)
                vim.fn.chanclose(chan, "stdin")
                vim.notify("Yanked path to tmux buffer: " .. path)
              end,
              desc = "yank file path to tmux",
            },
            ["_"] = "send_to_tmux",
            ["-"] = {
              function(state)
                require("neo-tree").config.commands.send_to_tmux(state, true)
              end,
            },
          },
        },
        nesting_rules = {},
        filesystem = {
          filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
            hide_hidden = true,
            hide_by_name = {},
            hide_by_pattern = {},
            always_show = {},
            always_show_by_pattern = {},
            never_show = {
              ".DS_Store",
            },
            never_show_by_pattern = {},
          },
          follow_current_file = {
            enabled = true,
            leave_dirs_open = false,
          },
          group_empty_dirs = true,
          hijack_netrw_behavior = "open_current",
          use_libuv_file_watcher = false,
          window = {
            mappings = {
              ["u"] = "navigate_up",
              ["<cr>"] = "set_root",
              ["."] = {
                function(state)
                  state.filtered_items.hide_dotfiles = not state.filtered_items.hide_dotfiles
                  require("neo-tree.sources.filesystem")._navigate_internal(state, nil, nil, nil, false)
                end,
                desc = "toggle_hidden",
              },
              ["gi"] = {
                function(state)
                  state.filtered_items.hide_gitignored = not state.filtered_items.hide_gitignored
                  require("neo-tree.sources.filesystem")._navigate_internal(state, nil, nil, nil, false)
                end,
                desc = "toggle_gitignore",
              },
              ["/"] = "fuzzy_finder",
              ["#"] = "fuzzy_sorter",
              ["<c-r>"] = "clear_filter",
              ["[c"] = "prev_git_modified",
              ["]c"] = "next_git_modified",
              ["S"] = { "show_help", nowait = false, config = { title = "Sort by", prefix_key = "S" } },
              ["Sc"] = { "order_by_created", nowait = false },
              ["Sd"] = { "order_by_diagnostics", nowait = false },
              ["Sg"] = { "order_by_git_status", nowait = false },
              ["Sm"] = { "order_by_modified", nowait = false },
              ["Sn"] = { "order_by_name", nowait = false },
              ["Ss"] = { "order_by_size", nowait = false },
              ["St"] = { "order_by_type", nowait = false },
              -- ['<key>'] = function(state) ... end,
            },
            fuzzy_finder_mappings = {
              ["<down>"] = "move_cursor_down",
              ["<C-n>"] = "move_cursor_down",
              ["<up>"] = "move_cursor_up",
              ["<C-p>"] = "move_cursor_up",
            },
          },
        },
      }
      vim.keymap.set("x", "-", function()
        require("neo-tree").config.commands.send_to_tmux(nil, true)
      end, { noremap = false })
      vim.keymap.set("x", "_", require("neo-tree").config.commands.send_to_tmux, { noremap = false })
    end,
  },
  {
    "christoomey/vim-tmux-navigator",
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
    },
    keys = {
      { "<c-h>", "<cmd><C-U>TmuxNavigateLeft<cr>" },
      { "<c-j>", "<cmd><C-U>TmuxNavigateDown<cr>" },
      { "<c-k>", "<cmd><C-U>TmuxNavigateUp<cr>" },
      { "<c-l>", "<cmd><C-U>TmuxNavigateRight<cr>" },
      { "<c-\\>", "<cmd><C-U>TmuxNavigatePrevious<cr>" },
    },
  },
}

vim.api.nvim_create_autocmd("TextYankPost", {
  desc = "sync yanked text to tmux buffer",
  group = vim.api.nvim_create_augroup("yank", { clear = true }),
  callback = function()
    local chan = vim.fn.jobstart({ "tmux", "loadb", "-" }, { stdin = "pipe" })
    vim.fn.chansend(chan, vim.fn.trim(vim.fn.getreg '"'))
    vim.fn.chanclose(chan, "stdin")
  end,
})

vim.cmd [[ colorscheme tokyonight-night ]]
vim.o.cursorline = true
