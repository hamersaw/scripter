#!/bin/bash

usage="usage $(basename $0) var <SUBCOMMAND>
SUBCOMMANDS:
    clear                   unset all variables
    get <name>              retrieve the value for a specified variable
    help                    display this menu
    list                    display all set variables
    set <name> <value>      set the value for a specified variable
    unset <name>            unset the value for a specified variable"
listfmt="%-30s%-30s\n"
listdivlen=60

# execute command
case "$1" in
    clear)
        cat /dev/null > $varfile
        ;;
    get)
        # check argument length
        (( $# != 2 )) && echo "'get' requires one argument" && exit 1

        # retrieve variable value if exists
        cat $varfile | grep "^$2 " | awk '{print $2}'
        ;;
    help)
        echo "$usage"
        ;;
    list)
        printf "$listfmt" "name" "value"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"
        cat $varfile | awk -v fmt="$listfmt" \
            '{printf fmt, $1, $2}'
        ;;
    set)
        # check argument length
        (( $# != 3 )) && echo "'set' requires two arguments" && exit 1

        # check if 'variable' already exists
        cat $varfile | grep -q "^$2 " && \
            echo "variable '$2' already exists" && exit 1

        # add 'variable' and 'value' to varfile
        echo "$2 $3" >> $varfile
        sort -o $varfile $varfile
        ;;
    unset)
        # check argument length
        (( $# != 2 )) && echo "'unset' requires one argument" && exit 1

        # remove 'variable' from varfile
        sed -i "/^$2/d" $varfile
        ;;
    *)
        echo "$usage"
        exit 1
        ;;
esac
