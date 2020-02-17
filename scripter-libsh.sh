#!/bin/bash

get_or_else() {
    for arg in ${@:2:$#}; do
        IFS='=' read -ra ARRAY <<< "$arg"
        if [ "$1" == "${ARRAY[0]}" ]; then
            local value="${ARRAY[1]}"
        fi
    done

    [ -z "$value" ] && local value="$2"
    echo $value
    return 0
}

get_or_fail() {
    for arg in ${@:1:$#}; do
        IFS='=' read -ra ARRAY <<< "$arg"
        if [ "$1" == "${ARRAY[0]}" ]; then
            local value="${ARRAY[1]}"
        fi
    done

    [ -z "$value" ] && return 1
    echo $value
    return 0
}
