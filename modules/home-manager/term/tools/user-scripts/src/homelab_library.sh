#!/usr/bin/env bash

clamp() {
    local value="$1"
    local min_value="$2"
    local max_value="$3"

    if [ "$value" -lt "$min_value" ]; then
        printf '%s\n' "$min_value"
    elif [ "$value" -gt "$max_value" ]; then
        printf '%s\n' "$max_value"
    else
        printf '%s\n' "$value"
    fi
}

round_to_nearest_step() {
    local value="$1"
    local step="$2"
    printf '%s\n' $((((value + (step / 2)) / step) * step))
}
