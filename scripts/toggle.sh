#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/variables.sh"

# script global vars
ARGS="$1"               # example args format: "nvim,python3,right,20,0.5,focus"
PANE_ID="$2"
NVIM_COMMAND="$(echo "$ARGS"  | cut -d',' -f1)"   # "nvim"
PYTHON_COMMAND="$(echo "$ARGS"  | cut -d',' -f2)"   # "python3"
POSITION="$(echo "$ARGS" | cut -d',' -f3)"   # "right"
SIZE="$(echo "$ARGS"     | cut -d',' -f4)"   # "20"
REFRESH_INTERVAL="$(echo "$ARGS"    | cut -d',' -f5)"   # "0.5"
ENABLE_DEBUG_PANE="$(echo "$ARGS"    | cut -d',' -f6)"   # "0"
FOCUS="$(echo "$ARGS"    | cut -d',' -f7)"   # "focus"

PANE_WIDTH="$(get_pane_info "$PANE_ID" "#{pane_width}")"
PANE_CURRENT_PATH="$(get_pane_info "$PANE_ID" "#{pane_current_path}")"

supported_tmux_version_ok() {
	$CURRENT_DIR/check_tmux_version.sh "$SUPPORTED_TMUX_VERSION"
}

sidebar_registration() {
	get_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" ""
}

sidebar_pane_id() {
	sidebar_registration |
		cut -d',' -f1
}

sidebar_pane_args() {
	echo "$(sidebar_registration)" |
		cut -d',' -f2-
}

register_sidebar() {
	local sidebar_id="$1"
	set_tmux_option "${REGISTERED_SIDEBAR_PREFIX}-${sidebar_id}" "$PANE_ID"
	set_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" "${sidebar_id},${ARGS}"
}

registration_not_for_the_same_command() {
	local registered_args="$(sidebar_registration | cut -d',' -f2-)"
	[[ $ARGS != $registered_args ]]
}

sidebar_exists() {
	local pane_id="$(sidebar_pane_id)"
	tmux list-panes -F "#{pane_id}" 2>/dev/null |
		\grep -q "^${pane_id}$"
}

has_sidebar() {
	if [ -n "$(sidebar_registration)" ] && sidebar_exists; then
		return 0
	else
		return 1
	fi
}

current_pane_width_not_changed() {
	if [ $PANE_WIDTH -eq $1 ]; then
		return 0
	else
		return 1
	fi
}

kill_sidebar() {
	# get data before killing the sidebar
	local sidebar_pane_id="$(sidebar_pane_id)"
	local sidebar_args="$(sidebar_pane_args)"
	local sidebar_position="$(echo "$sidebar_args" | cut -d',' -f2)" # left or defults to right
	local sidebar_width="$(get_pane_info "$sidebar_pane_id" "#{pane_width}")"

	$CURRENT_DIR/save_sidebar_width.sh "$PANE_CURRENT_PATH" "$sidebar_width"

	# kill the sidebar
	tmux kill-pane -t "$sidebar_pane_id"

	# check current pane "expanded" properly
	local new_current_pane_width="$(get_pane_info "$PANE_ID" "#{pane_width}")"
	if current_pane_width_not_changed "$new_current_pane_width"; then
		# need to expand current pane manually
		local direction_flag
		if [[ "$sidebar_position" =~ "left" ]]; then
			direction_flag="-L"
		else
			direction_flag="-R"
		fi
		# compensate 1 column
		tmux resize-pane "$direction_flag" "$((sidebar_width + 1))"
	fi
	PANE_WIDTH="$new_current_pane_width"
}

sidebar_left() {
	[[ $POSITION =~ "left" ]]
}

no_focus() {
	if [[ $FOCUS =~ (^focus) ]]; then
		return 1
	else
		return 0
	fi
}

size_defined() {
	[ -n $SIZE ]
}

desired_sidebar_size() {
	local half_pane="$((PANE_WIDTH / 2))"
	if directory_in_sidebar_file "$PANE_CURRENT_PATH"; then
		# use stored sidebar width for the directory
		echo "$(width_from_sidebar_file "$PANE_CURRENT_PATH")"
	elif size_defined && [ $SIZE -lt $half_pane ]; then
		echo "$SIZE"
	else
		echo "$half_pane"
	fi
}

# tmux version 2.0 and below requires different argument for `join-pane`
use_inverted_size() {
	[ tmux_version_int -le 20 ]
}

# Root dir is either the current dir or git root dir.
get_nvimtree_root_dir() {
	if command -v \git &> /dev/null
	then
		git_root_dir="$(\git -C "$PANE_CURRENT_PATH" rev-parse --show-toplevel 2>/dev/null)"
		if [ -z "$git_root_dir" ]
		then
			echo '.'
		else
			echo "$git_root_dir"
		fi
	else
		echo '.'
	fi
}

split_sidebar_left() {
	local sidebar_size=$(desired_sidebar_size)
	if use_inverted_size; then
		sidebar_size=$((PANE_WIDTH - $sidebar_size - 1))
	fi

	side_pane_root="$(get_nvimtree_root_dir)"
	nvim_addr="$(mktemp --dry-run -t kiyoon-tmux-sidenvimtree-$PANE_ID.XXXXXX)"
	local sidebar_id="$(tmux new-window -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}" "'$NVIM_COMMAND' '$side_pane_root' --listen '$nvim_addr'")"
	tmux join-pane -hb -l "$sidebar_size" -t "$PANE_ID" -s "$sidebar_id"

	if [[ $ENABLE_DEBUG_PANE -eq 0 ]]
	then
		"$CURRENT_DIR/nvimtree/watch_and_update.sh" "$PANE_ID" "$sidebar_id" "$side_pane_root" "$nvim_addr" $REFRESH_INTERVAL "$NVIM_COMMAND" "$PYTHON_COMMAND" &>/dev/null &
	else
		local sidebar_id2="$(tmux split-window -h -l "$sidebar_size" -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}" "'$CURRENT_DIR/nvimtree/watch_and_update.sh' '$PANE_ID' '$sidebar_id' '$side_pane_root' '$nvim_addr' $REFRESH_INTERVAL '$NVIM_COMMAND' '$PYTHON_COMMAND'; sleep 100")"
	fi
	echo "$sidebar_id"
}

split_sidebar_right() {
	local sidebar_size=$(desired_sidebar_size)
	side_pane_root="$(get_nvimtree_root_dir)"
	nvim_addr="$(mktemp --dry-run -t kiyoon-tmux-sidenvimtree-$PANE_ID.XXXXXX)"
	local sidebar_id="$(tmux split-window -h -l "$sidebar_size" -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}" "'$NVIM_COMMAND' '$side_pane_root' --listen '$nvim_addr'")"
	if [[ $ENABLE_DEBUG_PANE -eq 0 ]]
	then
		"$CURRENT_DIR/nvimtree/watch_and_update.sh" "$PANE_ID" "$sidebar_id" "$side_pane_root" "$nvim_addr" $REFRESH_INTERVAL "$NVIM_COMMAND" "$PYTHON_COMMAND" &> /dev/null &
	else
		local sidebar_id2="$(tmux new-window -c "$PANE_CURRENT_PATH" -P -F "#{pane_id}" "'$CURRENT_DIR/nvimtree/watch_and_update.sh' '$PANE_ID' '$sidebar_id' '$side_pane_root' '$nvim_addr' $REFRESH_INTERVAL '$NVIM_COMMAND' '$PYTHON_COMMAND'; sleep 100")"
		tmux join-pane -hb -l "$sidebar_size" -t "$PANE_ID" -s "$sidebar_id2"
	fi
	echo "$sidebar_id"
}

create_sidebar() {
	local position="$1" # left / right
	local sidebar_id="$(split_sidebar_${position})"
	register_sidebar "$sidebar_id"
	if no_focus; then
		tmux last-pane
	fi
}

current_pane_is_sidebar() {
	local var="$(get_tmux_option "${REGISTERED_SIDEBAR_PREFIX}-${PANE_ID}" "")"
	[ -n "$var" ]
}

current_pane_too_narrow() {
	[ $PANE_WIDTH -lt $MINIMUM_WIDTH_FOR_SIDEBAR ]
}

execute_command_from_main_pane() {
	# get pane_id for this sidebar
	local main_pane_id="$(get_tmux_option "${REGISTERED_SIDEBAR_PREFIX}-${PANE_ID}" "")"
	# execute the same command as if from the "main" pane
	$CURRENT_DIR/toggle.sh "$ARGS" "$main_pane_id"
}

exit_if_pane_too_narrow() {
	if current_pane_too_narrow; then
		display_message "Pane too narrow for the sidebar"
		exit
	fi
}

toggle_sidebar() {
	if has_sidebar; then
		kill_sidebar
		# if using different sidebar command automatically open a new sidebar
		# if registration_not_for_the_same_command; then
		# 	create_sidebar
		# fi
	else
		exit_if_pane_too_narrow
		if sidebar_left; then
			create_sidebar "left"
		else
			create_sidebar "right"
		fi
	fi
}

main() {
	if supported_tmux_version_ok; then
		if current_pane_is_sidebar; then
			execute_command_from_main_pane
		else
			toggle_sidebar
		fi
	fi
}
main
