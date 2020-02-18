#!/bin/bash

usage="usage $(basename $0) repo <SUBCOMMAND>
SUBCOMMANDS:
    add <name> <git-url>    add the specified repository with git url
    clear                   clear the list of registered repositories
    help                    display this menu
    list                    display all registered repositories
    remove <name>           remove the specified repository
    update                  update modules by syncing repositories"
listfmt="%-15s%-35s\n"
listdivlen=60

# execute command
case "$1" in
    add)
        # check argument length
        (( $# != 3 )) && echo "'add' requires one argument" && exit 1

        # check if 'name' already exists
        cat $repofile | grep -q "^$2 " && \
            echo "repository '$2' already exists" && exit 1

        # add 'name' and 'url' to repofile
        echo "$2 $3" >> $repofile
        sort -o $repofile $repofile
        ;;
    clear)
        cat /dev/null > $repofile
        ;;
    help)
        echo "$usage"
        ;;
    list)
        printf "$listfmt" "name" "url"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"
        cat $repofile | awk -v fmt="$listfmt" \
            '{printf fmt, $1, $2}'
        ;;
    remove)
        # check argument length
        (( $# != 2 )) && echo "'remove' requires one argument" && exit 1

        # remove 'name' from repofile
        sed -i "/^$3/d" $repofile
        ;;
    update)
        # iterate over repofile
        while read LINE; do
            array=($LINE)
            repodir="$moddir/${array[0]}"

            if [ -d "$repodir" ]; then
                # repo exists -> git pull
                PWD=$(pwd)
                cd "$repodir"
                git pull > /dev/null
                cd "$PWD"
            else
                # repo does not exist -> git clone
                git clone "${array[1]}" "$repodir" > /dev/null
            fi
        done < $repofile
        ;;
    *)
        echo "$usage"
        exit 1
        ;;
esac
