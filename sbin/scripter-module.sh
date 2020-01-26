#!/bin/bash

usage="usage $(basename $0) [COMMAND]
COMMANDS:
    help                    display this menu
    list                    display available modules
    run <module-name>       run the specified module
    show <module-name>      show information on the specified module"

listfmt="%-30s%-50s%-5s\n"
listdivlen=90

get_json() {
    echo ${1//\'/\"} | python3 -c "import sys, json; \
        print(json.load(sys.stdin)['$2'])" 2>/dev/null
}

get_json_keys() {
    echo ${1//\'/\"} | python3 -c "import sys, json; \
        print(*json.load(sys.stdin).keys())"
}

get_json_list() {
    echo ${1//\'/\"} | python3 -c "import sys, json; \
        print(json.load(sys.stdin)[$2])" 2>/dev/null
}

# load project directory and file configurations
projectdir="$(pwd)/$(dirname $0)/.."
. $projectdir/sbin/config.sh

# execute command
case "$1" in
    help)
        printf "$usage\n"
        ;;
    list)
        printf "$listfmt" "name" "description" "background"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"

        for configfile in $(ls $moddir/*/config.js); do
            # retrieve modules list for this repository
            json=$(cat $configfile)
            keys=$(get_json_keys "$json")
            modules=($keys)

            # compute repository name
            reponame=${configfile/$moddir/} # strip moddir
            reponame=${reponame/config.js/} # strip 'config.js'
            reponame="${reponame:1:${#reponame}-2}" # strip /'s

            # iterate over modules
            for module in ${modules[@]}; do
                modulejson=$(get_json "$json" "$module")
                description=$(get_json "$modulejson" "description")
                background=$(get_json "$modulejson" "background")

                printf "$listfmt" "$reponame/$module" \
                    "$description" "$background"
            done
        done
        ;;
    run)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'run' command requires one argument" && exit 1

        # compute reponame and scriptname
        reponame=$(echo "$2" | cut -f 1 -d "/")
        scriptname=${2/$reponame/} # strip reponame
        scriptname="${scriptname:1:${#scriptname}-1}" # strip leading /

        # check if module exists
        json=$(cat $moddir/$reponame/config.js)
        modulejson=$(get_json "$json" "$scriptname")
        [ -z "$modulejson" ] && echo "module '$2' does not exist" && exit 1

        # populate options 
        optionS=$(get_json "$modulejson" "options")
        count=0
        optionstring=""
        for (( ; ; )); do
            # get next option in list
            option=$(get_json_list "$optionS" "$count")
            if [ $? -eq 0 ]; then
                name=$(get_json "$option" "name")
                required=$(get_json "$option" "required")

                # retrieve value from variable store
                value=$(${0/module/variable} get $name)
                [ -z $value ] && [ $required = "true" ] && \
                    echo "required variable '$name' is not set" && exit 1

                # append to optionstring
                if [ -z $optionstring ]; then
                    optionstring="$name=$value"
                else
                    optionstring="$optionstring $name=$value"
                fi
            else
                break
            fi

            (( count += 1 ))
        done

        # execute module
        modulefile="$moddir/$2"
        background=$(get_json "$modulejson" "background")
        case $background in
            true)
                # execute in background
                pid="$RANDOM"
                $modulefile "$optionstring" >$logdir/$pid.log 2>&1 &

                echo "$pid $! $(date +%Y.%m.%d-%H:%M:%S) \
                    $2 \"$optionstring\"" >> $procfile
                echo "executed as pid $pid"
                ;;
            false)
                $modulefile "$optionstring"
                ;;
            *)
                echo "module 'background' must be set to 'true' or 'false'"
                exit 1
                ;;
        esac
        ;;
    show)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'show' command requires one argument" && exit 1

        # compute reponame and scriptname
        reponame=$(echo "$2" | cut -f 1 -d "/")
        scriptname=${2/$reponame/} # strip reponame
        scriptname="${scriptname:1:${#scriptname}-1}" # strip leading /

        # check if module exists
        json=$(cat $moddir/$reponame/config.js)
        modulejson=$(get_json "$json" "$scriptname")
        [ -z "$modulejson" ] && echo "module '$2' does not exist" && exit 1

        # print module
        echo ${modulejson//\'/\"}
        ;;
    *)
        printf "$usage\n"
        exit 1
        ;;
esac
