#!/usr/bin/env bash

# Use this script to further register another pane's sidebar manually.
# This is used in nvim-tree-remote.nvim to register the sidebar of the
# new split.
# This way, you can turn off the sidebar from the editor pane.

CURRENT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

source "$CURRENT_DIR/helpers.sh"
source "$CURRENT_DIR/variables.sh"

# script global vars
PANE_ID="$1"
SIDEBAR_ID="$2"

ARGS=""		# This seems to be not necessary.

register_sidebar() {
	# set_tmux_option "${REGISTERED_SIDEBAR_PREFIX}-${sidebar_id}" "$PANE_ID"
	set_tmux_option "${REGISTERED_PANE_PREFIX}-${PANE_ID}" "${SIDEBAR_ID},${ARGS}"
}

main() {
	register_sidebar
}
main
