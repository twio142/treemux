#!/usr/bin/env bash

# ps -el | awk_by_name '{print $(f["PID"])}'
awk_by_name() {
	awk '
	{
		for (i = 1; i <= NF; i++) {
			f[$i] = i;
		}
	} '"$1"
}

awk_last_field() {
	awk '
	NR == 1 {
		column_count = NF;
	}
	NR > 1 {
		for (i = column_count; i <= NF; i++) {
			if (i > column_count) {
				printf " ";
			}
			printf "%s", $i;
		}
		printf "\n";
	}
	'
}
