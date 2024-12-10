#!/usr/bin/env bash
# Author: Kiyoon Kim (https://github.com/kiyoon)

if [[ $# -ne 9 ]]; then
	echo "Usage: $0 <MAIN_PANE_ID> <SIDE_PANE_ID> <SIDE_PANE_ROOT> <NVIM_ADDR> <REFRESH_INTERVAL> <REFRESH_INTERVAL_INACTIVE_PANE> <REFRESH_INTERVAL_INACTIVE_WINDOW> <NVIM_COMMAND> <PYTHON_COMMAND>"
	echo "Arthor: Kiyoon Kim (https://github.com/kiyoon)"
	echo "Track directory changes in the main pane, and refresh the side pane's Nvim-Tree every <REFRESH_INTERVAL> seconds."
	echo "When going into child directories (cd dir), the side pane will keep the root directory."
	echo "When going out of the root directory (cd /some/dir), the side pane will change the root directory to that of the main pane."
	exit 100
fi

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR"/awk_helper.sh

MAIN_PANE_ID="$1"
SIDE_PANE_ID="$2"
SIDE_PANE_ROOT="$3"
NVIM_ADDR="$4"
REFRESH_INTERVAL="$5"
REFRESH_INTERVAL_INACTIVE_PANE="$6"
REFRESH_INTERVAL_INACTIVE_WINDOW="$7"
NVIM_COMMAND="$8"
PYTHON_COMMAND="$9"

echo "$NVIM_COMMAND"

echo "$0 $@"
echo "OSTYPE: $OSTYPE"	# log OS type
tmux -V					# log tmux version

main_pane_exists=1
side_pane_exists=1
tmux list-panes -t "$MAIN_PANE_ID" &> /dev/null
[ "$?" -ne 0 ] && main_pane_exists=0
tmux list-panes -t "$SIDE_PANE_ID" &> /dev/null
[ "$?" -ne 0 ] && side_pane_exists=0

# `tmux display` doesn't match strictly and it will give you any pane if not found.
main_pane_pid=$(tmux display -pt "$MAIN_PANE_ID" '#{pane_pid}')
if [[ -z $main_pane_pid ]]
then
	echo "Main pane $MAIN_PANE_ID does not exist."
	exit 101
fi

echo "Watching main pane (pid = $main_pane_pid)"
main_pane_prevcwd=$(lsof -a -d cwd -p "$main_pane_pid" 2> /dev/null | awk_last_field)
# This does not work on MacOS.
#main_pane_prevcwd=$(readlink -f "/proc/$main_pane_pid/cwd")
side_pane_root="$main_pane_prevcwd"

# `tmux display` doesn't match strictly and it will give you any pane if not found.
side_pane_pid=$(tmux display -pt "$SIDE_PANE_ID" '#{pane_pid}')
if [[ -z $side_pane_pid ]]
then
	echo "Side pane $SIDE_PANE_ID not found. Exiting."
	exit 102
fi

echo "Updating side pane (Nvim-Tree, pid = $side_pane_pid)"

echo "Initial main pane cwd: $main_pane_prevcwd"
echo "Initial nvim-tree pane root: $SIDE_PANE_ROOT"
echo "Waiting for the nvim-tree.."
nvimtree_root_dir=$("$PYTHON_COMMAND" "$CURRENT_DIR/wait_nvimtreeinit_and_open_dir.py" "$NVIM_ADDR" "$main_pane_prevcwd" "$SIDE_PANE_ROOT")
exit_code=$?
if [[ $exit_code -ne 0 ]]
then
	echo "$CURRENT_DIR/wait_nvimtreeinit_and_open_dir.py exited with code $exit_code."
	if [[ $exit_code -eq 50 ]]
	then
		echo "pynvim not installed. Continuing without pynvim but recommended to install it."
		sleep 2
	elif [[ $exit_code -eq 51 ]]
	then
		echo "Nvim is not installed or could not be loaded. Exiting.."
		exit 103
	elif [[ $exit_code -eq 52 ]]
	then
		echo "Nvim-Tree is not installed or could not be loaded. Exiting.."
		echo "$nvimtree_root_dir"	# error message
		exit 104
	else
		echo "Unknown error. Exiting.."
		echo "$nvimtree_root_dir"	# error message
		exit 105
	fi
else
	echo "Nvim-Tree detected!"
	echo "Detected side pane root: $nvimtree_root_dir"
	side_pane_root="$nvimtree_root_dir"
fi

while [[ $main_pane_exists -eq 1 ]] && [[ $side_pane_exists -eq 1 ]]; do
	# optional: check if sidebar is running `nvim .`
	# This does not work well in Mac..
	# command_pid=$(ps -el | awk "\$5==$side_pane_pid" | awk '{print $4}')
	# if [[ -z $command_pid ]]	# no command is running
	# then
	# 	echo "Exiting due to side pane having no command running. (pid = $side_pand_pid)"
	# 	break
	# else
	# 	full_command=$(ps --no-headers -u -p $command_pid | awk '{for(i=11;i<=NF;++i)printf $i" "}' | xargs)	# xargs does trimming
	# 	if [[ "$full_command" != "'$NVIM_COMMAND' . --listen "* ]]
	# 	then
	# 		echo "Exiting due to side pane not running 'nvim . --listen ...'. Instead, it's running: $full_command"
	# 		break
	# 	fi
	# fi

	main_pane_cwd=$(lsof -a -d cwd -p "$main_pane_pid" 2> /dev/null | awk_last_field)
	# This does not work on MacOS.
	#main_pane_cwd=$(readlink -f "/proc/$main_pane_pid/cwd")
	echo $main_pane_cwd

	if [[ -z "$main_pane_cwd" ]]
	then
		echo "Can't find main pane's cwd. Exiting.."
		break
	fi

	# Dir changed?
	if [[ "$main_pane_cwd" != "$main_pane_prevcwd" ]]
	then
		if [[ "$main_pane_cwd"/ != "$side_pane_root"/* ]]	# it should not go through when it's the same dir.
		then
			# Root completely changed
			echo "Root changed: $main_pane_cwd"
			"$PYTHON_COMMAND" "$CURRENT_DIR/change_root.py" "$NVIM_ADDR" "$main_pane_cwd"

			if [[ $? -ne 0 ]]; then
				echo "Error using pynvim. Trying tmux send-keys."
				tmux send-keys -t "$SIDE_PANE_ID" \
					Escape ":e $main_pane_cwd" Enter
			fi
			side_pane_root="$main_pane_cwd"
		else
			if [[ "$main_pane_cwd" == "$main_pane_prevcwd"/* ]] || [[ "$main_pane_prevcwd" == "$main_pane_cwd"/* ]] || [[ "$main_pane_cwd" == "$side_pane_root"/* ]]; then
				echo "Opening directory: $main_pane_cwd"
				new_root_dir=$("$PYTHON_COMMAND" "$CURRENT_DIR/go_random_within_rootdir.py" "$NVIM_ADDR" "$main_pane_cwd" "$side_pane_root")

				if [[ $? -ne 0 ]]; then
					echo "Error using pynvim. Trying tmux send-keys."
					tmux send-keys -t "$SIDE_PANE_ID" \
						Escape ":lua require('neo-tree.command').execute({ action = 'focus', reveal_file = '$main_pane_cwd', reveal_force_cwd = true })" Enter
				else
					side_pane_root="$new_root_dir"
				fi
			fi
		fi
		main_pane_prevcwd="$main_pane_cwd"
	fi

	main_pane_active=$(tmux display -pt "$MAIN_PANE_ID" '#{pane_active}')
	side_pane_active=$(tmux display -pt "$SIDE_PANE_ID" '#{pane_active}')
	window_active=$(tmux display -pt "$MAIN_PANE_ID" '#{window_active}')

	if [[ "$main_pane_active" -eq 1 || "$side_pane_active" -eq 1 ]]; then
		sleep "$REFRESH_INTERVAL"
	elif [[ "$window_active" -eq 1 ]]; then
		# Pane inactive but still in the same window
		sleep "$REFRESH_INTERVAL_INACTIVE_PANE"
	else
		# Window inactive
		sleep "$REFRESH_INTERVAL_INACTIVE_WINDOW"
	fi

	tmux list-panes -t "$MAIN_PANE_ID" &> /dev/null
	[ "$?" -ne 0 ] && main_pane_exists=0
	tmux list-panes -t "$SIDE_PANE_ID" &> /dev/null
	[ "$?" -ne 0 ] && side_pane_exists=0
done
