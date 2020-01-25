#!/bin/bash

usage() {
    echo "USAGE $(basename $0) [COMMAND]
COMMANDS:
    clear
    get
    help
    list
    set
    unset"
}

# initialize variables
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

# execute command
case "$1" in
    clear)
        rm $VARFILE
        touch $VARFILE
        ;;
    get)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'get' command requires one argument" && exit 1

        # retrieve variable value if exists
        cat $VARFILE | grep "^$2 " | awk '{print $2}'
        ;;
    help)
        usage
        exit 0
        ;;
    list)
        printf "%-30s%-30s\n" "name" "value"
        echo "------------------------------------------------------------"
        cat $VARFILE | awk '{printf "%-30s%-30s\n", $1, $2}'
        ;;
    set)
        # check argument length
        (( $# != 3 )) && \
            echo "the 'set' command requires two arguments" && exit 1

        # check if variable already exists
        cat $VARFILE | grep -q "^$2 " && \
            echo "variable '$2' already exists" && exit 1

        # add 'VARIABLE' and 'VALUE' to VARFILE
        echo "$2 $3" >> $VARFILE
        sort -o $VARFILE $VARFILE
        ;;
    unset)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'unset' command requires one argument" && exit 1

        # remove variable from VARFILE
        sed -i "/^$3/d" $VARFILE
        ;;
    *)
        usage
        exit 1
        ;;
esac
