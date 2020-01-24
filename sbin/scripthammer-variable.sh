#!/bin/bash

usage() {
    echo "USAGE $(basename $0) [COMMAND]
COMMANDS:
    get
    help
    list
    search
    set
    unset"
}

# initialize variables
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

# execute command
case "$1" in
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
        cat $VARFILE | awk '{print $1,":",$2}'
        ;;
    search)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'search' command requires one argument" && exit 1

        # retrieve variable value if exists
        cat $VARFILE | grep "$2" | awk '{print $1,$2}'
        ;;
    set)
        # check argument length
        (( $# != 3 )) && \
            echo "the 'set' command requires two arguments" && exit 1

        # add 'KEY' and 'VALUE' to VARFILE
        mv $VARFILE $VARFILE.tmp
        { echo "$2 $3"; cat $VARFILE.tmp; } | sort  > $VARFILE
        rm $VARFILE.tmp
        ;;
    unset)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'unset' command requires one argument" && exit 1

        # remove row from VARFILE
        mv $VARFILE $VARFILE.tmp
        cat $VARFILE.tmp | sed "/^$2*/d" > $VARFILE
        rm $VARFILE.tmp
        ;;
    *)
        usage
        exit 1
        ;;
esac
