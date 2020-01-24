#!/bin/bash

usage() {
    echo "USAGE $(basename $0) [COMMAND]
COMMANDS:
    help
    list
    show"
}

# initialize variables
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

# execute command
case "$1" in
    help)
        usage
        exit 0
        ;;
    list)
        echo "TODO - list"
        ;;
    show)
        echo "TODO - show"
        ;;
    *)
        usage
        exit 1
        ;;
esac
