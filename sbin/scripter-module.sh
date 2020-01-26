#!/bin/bash

USAGE="USAGE $(basename $0) [COMMAND]
COMMANDS:
    help                    display this menu
    list                    display available modules
    run <module-name>       run the specified module
    show <module-name>      show information on the specified module"

LISTFMT="%-30s%-60s%-5s\n"
LISTDIVLEN=100

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
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

# execute command
case "$1" in
    help)
        printf "$USAGE\n"
        exit 0
        ;;
    list)
        printf "$LISTFMT" "name" "description" "background"
        printf "%.0s-" $(seq 1 $LISTDIVLEN); printf "\n"

        for CONFIGFILE in $(ls $MODDIR/*/config.js); do
            # retrieve modules list for this repository
            JSON=$(cat $CONFIGFILE)
            KEYS=$(get_json_keys "$JSON")
            MODULES=($KEYS)

            # compute repository name
            REPONAME=${CONFIGFILE/$MODDIR/} # strip MODDIR
            REPONAME=${REPONAME/config.js/} # strip 'config.js'
            REPONAME="${REPONAME:1:${#REPONAME}-2}" # strip /'s

            # iterate over modules
            for MODULE in ${MODULES[@]}; do
                MODULEJSON=$(get_json "$JSON" "$MODULE")
                DESCRIPTION=$(get_json "$MODULEJSON" "description")
                BACKGROUND=$(get_json "$MODULEJSON" "background")

                printf "$LISTFMT" "$REPONAME/$MODULE" \
                    "$DESCRIPTION" "$BACKGROUND"
            done
        done
        ;;
    run)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'run' command requires one argument" && exit 1

        # compute REPONAME and SCRIPTNAME
        REPONAME=$(echo "$2" | cut -f 1 -d "/")
        SCRIPTNAME=${2/$REPONAME/} # strip REPONAME
        SCRIPTNAME="${SCRIPTNAME:1:${#SCRIPTNAME}-1}" # strip leading /

        # check if module exists
        JSON=$(cat $MODDIR/$REPONAME/config.js)
        MODULEJSON=$(get_json "$JSON" "$SCRIPTNAME")
        [ -z "$MODULEJSON" ] && echo "module '$2' does not exist" && exit 1

        # populate options 
        OPTIONS=$(get_json "$MODULEJSON" "options")
        COUNT=0
        OPTIONSTRING=""
        for (( ; ; )); do
            # get next option in list
            OPTION=$(get_json_list "$OPTIONS" "$COUNT")
            if [ $? -eq 0 ]; then
                NAME=$(get_json "$OPTION" "name")
                REQUIRED=$(get_json "$OPTION" "required")

                # retrieve value from variable store
                VALUE=$(${0/module/variable} get $NAME)
                [ -z $VALUE ] && [ $REQUIRED = "true" ] && \
                    echo "required variable '$NAME' is not set" && exit 1

                # append to OPTIONSTRING
                if [ -z $OPTIONSTRING ]; then
                    OPTIONSTRING="$NAME=$VALUE"
                else
                    OPTIONSTRING="$OPTIONSTRING;$NAME=$VALUE"
                fi
            else
                break
            fi

            (( COUNT += 1 ))
        done

        # execute module
        MODULEFILE="$MODDIR/$2"
        BACKGROUND=$(get_json "$MODULEJSON" "background")
        case $BACKGROUND in
            true)
                # execute in background
                PID="$RANDOM"
                $MODULEFILE "$OPTIONSTRING" >$LOGDIR/$PID.log 2>&1 &

                echo "$PID $! $(date +%Y.%m.%d-%H:%M) \
                    $2 $OPTIONSTRING" >> $PROCFILE
                echo "executed as pid $PID"
                ;;
            false)
                $MODULEFILE "$OPTIONSTRING"
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

        # compute REPONAME and SCRIPTNAME
        REPONAME=$(echo "$2" | cut -f 1 -d "/")
        SCRIPTNAME=${2/$REPONAME/} # strip REPONAME
        SCRIPTNAME="${SCRIPTNAME:1:${#SCRIPTNAME}-1}" # strip leading /

        # check if module exists
        JSON=$(cat $MODDIR/$REPONAME/config.js)
        MODULEJSON=$(get_json "$JSON" "$SCRIPTNAME")
        [ -z "$MODULEJSON" ] && echo "module '$2' does not exist" && exit 1

        # print module
        echo ${MODULEJSON//\'/\"}
        ;;
    *)
        printf "$USAGE\n"
        exit 1
        ;;
esac
