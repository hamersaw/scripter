#!/bin/bash

USAGE="USAGE $(basename $0) [COMMAND]
COMMANDS:
    add <name> <git-url>    add the specified repository with git url
    clear                   clear the list of registered repositories
    help                    display this menu
    list                    display all registered repositories
    remove <name>           reomte the specified repository
    update                  update modules by syncing repositories"

LISTFMT="%-10s%-30s\n"
LISTDIVLEN=50

# load project directory and file configurations
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

# execute command
case "$1" in
    add)
        # check argument length
        (( $# != 3 )) && \
            echo "the 'add' command requires one argument" && exit 1

        # check if 'name' already exists
        cat $REPOFILE | grep -q "^$2 " && \
            echo "repository '$2' already exists" && exit 1

        # add 'name' and 'url' to REPOFILE
        echo "$2 $3" >> $REPOFILE
        sort -o $REPOFILE $REPOFILE
        ;;
    clear)
        cat /dev/null > $REPOFILE
        ;;
    help)
        printf "$USAGE\n"
        exit 0
        ;;
    list)
        printf "$LISTFMT" "name" "url"
        printf "%.0s-" $(seq 1 $LISTDIVLEN); printf "\n"
        cat $REPOFILE | awk -v fmt="$LISTFMT" '{printf fmt, $1, $2}'
        ;;
    remove)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'remove' command requires one argument" && exit 1

        # remove 'name' from REPOFILE
        sed -i "/^$3/d" $REPOFILE
        ;;
    update)
        # iterate over REPOFILE
        while read LINE; do
            ARRAY=($LINE)
            REPODIR="$MODDIR/${ARRAY[0]}"

            if [ -d "$REPODIR" ]; then
                # repo exists -> git pull
                PWD=$(pwd)
                cd "$REPODIR"
                git pull > /dev/null
                cd "$PWD"
            else
                # repo does not exist -> git clone
                git clone "${ARRAY[1]}" "$REPODIR" > /dev/null
            fi
        done < $REPOFILE
        ;;
    *)
        printf "$USAGE\n"
        exit 1
        ;;
esac
