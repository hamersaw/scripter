#!/bin/bash

usage="usage $(basename $0) var <COMMAND>
COMMANDS:
    clear                   unset all variables
    get <name>              retrieve the value for a specified variable
    help                    display this menu
    list                    display all set variables
    set <name> <value>      set the value for a specified variable
    unset <name>            unset the value for a specified variable"
listfmt="\e[1;34m%-30s\e[1;32m\e[1;22m%-30s\e[m\n"
listdivlen=60

# execute command
case "$1" in
    clear)
        cat /dev/null >$varfile
        ;;
    get)
        # check argument length
        (( $# != 2 )) && printf \
            "$(fail "'get' requires one argument\n")" && exit 1

        # retrieve variable value if exists
        cat $varfile | grep "^$2 " | awk '{print $2}'
        ;;
    help)
        echo "$usage"
        ;;
    list)
        printf "$listfmt" "name" "value"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"

        while read line; do
            array=($line)
            printf "$listfmt" "${array[0]}" "${array[1]}"
        done <$varfile
        ;;
    set)
        # check argument length
        (( $# != 3 )) && printf \
            "$(fail "'set' requires two arguments\n")" && exit 1

        # check if 'variable' already exists
        cat $varfile | grep -q "^$2 " && printf \
            "$(fail "variable '$2' already exists\n")" && exit 1

        # add 'variable' and 'value' to varfile
        echo "$2 $3" >>$varfile
        sort -o $varfile $varfile

        printf "$(success "[+] set variable '$2' to '$3'\n")"
        ;;
    unset)
        # check argument length
        (( $# != 2 )) && printf \
            "$(fail "'unset' requires one argument\n")" && exit 1

        # remove 'variable' from varfile
        sed -i "/^$2/d" $varfile

        printf "$(success "[-] unset variable '$2'\n")"
        ;;
    *)
        echo "$usage"
        exit 1
        ;;
esac
