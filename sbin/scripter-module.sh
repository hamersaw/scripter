#!/bin/bash

USAGE="USAGE $(basename $0) [COMMAND]
COMMANDS:
    help                    display this menu
    list                    list available modules
    run <module-name>       run the specified module
    show <module-name>      show information on the specified module"

LISTFMT="%-30s%-60s%-5s\n"
LISTDIVLEN=100

get_json() {
    echo ${1//\'/\"} | python3 -c "import sys, json; \
        print(json.load(sys.stdin)['$2'])"
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

        # iterate over script json configuration files
        for CONFIGFILE in $(find $MODDIR -name "*.js"); do
            RELATIVEPATH=${CONFIGFILE/$MODDIR/} # strip MODDIR
            case $RELATIVEPATH in
                /*)
                    # strip leading /
                    RELATIVEPATH="${RELATIVEPATH:1:${#RELATIVEPATH}-1}"
                    ;;
            esac
            NAME="${RELATIVEPATH%.*}" # strip file extension

            JSON=$(cat $CONFIGFILE)
            DESCRIPTION=$(get_json "$JSON" "description")
            BACKGROUND=$(get_json "$JSON" "background")

            printf "$LISTFMT" "$NAME" "$DESCRIPTION" "$BACKGROUND"
        done
        ;;
    run)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'run' command requires one argument" && exit 1

        # check if module exists
        CONFIGFILE="$MODDIR/$2.js"
        [ ! -f $CONFIGFILE ] && echo "module '$2' does not exist" && exit 1

        # populate options 
        JSON=$(cat $CONFIGFILE)
        OPTIONS=$(get_json "$JSON" "options")
        
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
        EXTENSION=$(get_json "$JSON" "extension")
        MODULEFILE="$MODDIR/$2.$EXTENSION"

        BACKGROUND=$(get_json "$JSON" "background")
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

        # check if module exists
        CONFIGFILE="$MODDIR/$2.js"
        [ ! -f $CONFIGFILE ] && echo "module '$2' does not exist" && exit 1

        cat $CONFIGFILE
        ;;
    *)
        printf "$USAGE\n"
        exit 1
        ;;
esac
