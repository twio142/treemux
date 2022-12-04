#!/usr/bin/env bash

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTS_DIR="$CURRENT_DIR/scripts"

source "$SCRIPTS_DIR/helpers.sh"
source "$SCRIPTS_DIR/variables.sh"
source "$SCRIPTS_DIR/tree_helpers.sh"

set_default_key_binding_options() {
	local nvim_command="$(nvim_command)"
	local python_command="$(python_command)"
	local tree_key="$(tree_key)"
	local tree_focus_key="$(tree_focus_key)"
	local tree_position="$(tree_position)"
	local tree_width="$(tree_width)"
	local refresh_interval="$(refresh_interval)"
	local enable_debug_pane="$(enable_debug_pane)"

	set_tmux_option "${VAR_KEY_PREFIX}-${tree_key}" "${nvim_command},${python_command},${tree_position},${tree_width},${refresh_interval},${enable_debug_pane}"
	set_tmux_option "${VAR_KEY_PREFIX}-${tree_focus_key}" "${nvim_command},${python_command},${tree_position},${tree_width},${refresh_interval},${enable_debug_pane},focus"
}

set_key_bindings() {
	local stored_key_vars="$(stored_key_vars)"
	local search_var
	local key
	local pattern
	for option in $stored_key_vars; do
		key="$(get_key_from_option_name "$option")"
		value="$(get_value_from_option_name "$option")"
		tmux bind-key "$key" run-shell "$SCRIPTS_DIR/toggle.sh '$value' '#{pane_id}'"
	done
}

main() {
	set_default_key_binding_options
	set_key_bindings
}
main
