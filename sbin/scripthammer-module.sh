#!/bin/bash

usage() {
    echo "USAGE $(basename $0) [COMMAND]
COMMANDS:
    help
    list
    run
    show"
}

# initialize variables
. config.sh

# execute command
case "$1" in
    help)
        usage
        exit 0
        ;;
    list)
        # iterate over script json configuration files
        for FILE in $(find $MODDIR -name "*.js"); do
            echo "TODO - process $FILE"
        done
        ;;
    run)
        echo "TODO - run"
        ;;
    show)
        echo "TODO - show"
        ;;
    *)
        usage
        exit 1
        ;;
esac
