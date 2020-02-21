#!/bin/bash

usage="usage $(basename $0) repo <COMMAND>
COMMANDS:
    add <name> <git-url>    add the specified repository with git url
    clear                   clear the list of registered repositories
    help                    display this menu
    list                    display all registered repositories
    remove <name>           remove the specified repository
    update                  update modules by syncing repositories"
listfmt="\e[1;34m%-15s\e[1;32m\e[1;22m%-35s\e[m\n"
listdivlen=60

# execute command
case "$1" in
    add)
        # check argument length
        (( $# != 3 )) && printf \
            "$(fail "'add' requires two arguments\n")" && exit 1

        # check if 'name' already exists
        cat $repofile | grep -q "^$2 " && printf \
            "$(warn "[0] repository '$2' already exists")" && exit 1

        # add 'name' and 'url' to repofile
        echo "$2 $3" >>$repofile
        sort -o $repofile $repofile

        printf "$(success "[+] added repository '$2' : '$3'\n")"
        ;;
    clear)
        # clear repofile and delete all moddir directories
        cat /dev/null >$repofile
        rm -r $moddir/* >/dev/null 2>&1

        printf "$(success "[-] removed all repositories\n")"
        ;;
    help)
        echo "$usage"
        ;;
    list)
        printf "$listfmt" "name" "url"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"

        while read line; do
            array=($line)
            printf "$listfmt" "${array[0]}" "${array[1]}"
        done <$repofile
        ;;
    remove)
        # check argument length
        (( $# != 2 )) && printf \
            "$(fail "'remote' requires one argument\n")" && exit 1

        # remove 'name' from repofile and delete directory
        sed -i "/^$2/d" $repofile
        [ -d "$moddir/$2" ] && rm -rf $moddir/$2

        printf "$(success "[-] removed repository '$2'\n")"
        ;;
    update)
        # iterate over repofile
        while read line; do
            array=($line)
            repodir="$moddir/${array[0]}"

            if [ -d "$repodir" ]; then
                # repo exists -> git pull
                PWD=$(pwd)
                cd "$repodir"

                git pull >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    printf "$(success "[+] updated '${array[0]}'\n")"
                else
                    printf "$(warn "[0] failed to update '${array[0]}'\n")"
                fi

                cd "$PWD"
            else
                # repo does not exist -> git clone
                git clone "${array[1]}" "$repodir" >/dev/null 2>&1
                if [ $? -eq 0 ]; then
                    printf "$(success "[+] initialized '${array[0]}'\n")"
                else
                    printf "$(warn "[0] failed to initialize '${array[0]}'\n")"
                fi
            fi
        done <$repofile
        ;;
    *)
        echo "$usage"
        exit 1
        ;;
esac
