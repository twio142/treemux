# file sourced from ./sidebar.tmux

command_exists() {
	local command="$1"
	type "$command" >/dev/null 2>&1
}

refresh_interval() {
	get_tmux_option "$REFRESH_INTERVAL_OPTION" "$REFRESH_INTERVAL"
}

refresh_interval_inactive_pane() {
	get_tmux_option "$REFRESH_INTERVAL_INACTIVE_PANE" "$REFRESH_INTERVAL_INACTIVE_PANE"
}

refresh_interval_inactive_window() {
	get_tmux_option "$REFRESH_INTERVAL_INACTIVE_WINDOW" "$REFRESH_INTERVAL_INACTIVE_WINDOW"
}

nvim_command() {
	get_tmux_option "$NVIM_COMMAND_OPTION" "$NVIM_COMMAND"
}

python_command() {
	get_tmux_option "$PYTHON_COMMAND_OPTION" "$PYTHON_COMMAND"
}

tree_key() {
	get_tmux_option "$TREE_OPTION" "$TREE_KEY"
}

tree_focus_key() {
	get_tmux_option "$TREE_FOCUS_OPTION" "$TREE_FOCUS_KEY"
}

tree_position() {
	get_tmux_option "$TREE_POSITION_OPTION" "$TREE_POSITION"
}

tree_width() {
	get_tmux_option "$TREE_WIDTH_OPTION" "$TREE_WIDTH"
}

enable_debug_pane() {
	get_tmux_option "$ENABLE_DEBUG_PANE_OPTION" "$ENABLE_DEBUG_PANE"
}
