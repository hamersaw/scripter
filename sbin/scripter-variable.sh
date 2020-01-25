#!/bin/bash

USAGE="USAGE $(basename $0) [COMMAND]
COMMANDS:
    clear                   unset all variables
    get <name>              retrieve the value for a specified variable
    help                    display this menu
    list                    display all set variables
    set <name> <value>      set the value for a specified variable
    unset <name>            unset the value for a specified variable"

LISTFMT="%-30s%-30s\n"
LISTDIVLEN=60

# load project directory and file configurations
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

# execute command
case "$1" in
    clear)
        cat /dev/null > $VARFILE
        ;;
    get)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'get' command requires one argument" && exit 1

        # retrieve variable value if exists
        cat $VARFILE | grep "^$2 " | awk '{print $2}'
        ;;
    help)
        printf "$USAGE\n"
        exit 0
        ;;
    list)
        printf "$LISTFMT" "name" "value"
        printf "%.0s-" $(seq 1 $LISTDIVLEN); printf "\n"
        cat $VARFILE | awk -v fmt="$LISTFMT" '{printf fmt, $1, $2}'
        ;;
    set)
        # check argument length
        (( $# != 3 )) && \
            echo "the 'set' command requires two arguments" && exit 1

        # check if 'variable' already exists
        cat $VARFILE | grep -q "^$2 " && \
            echo "variable '$2' already exists" && exit 1

        # add 'variable' and 'value' to VARFILE
        echo "$2 $3" >> $VARFILE
        sort -o $VARFILE $VARFILE
        ;;
    unset)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'unset' command requires one argument" && exit 1

        # remove 'variable' from VARFILE
        sed -i "/^$3/d" $VARFILE
        ;;
    *)
        printf "$USAGE\n"
        exit 1
        ;;
esac
