#!/bin/bash

USAGE="USAGE $(basename $0) [COMMAND]
COMMANDS:
    clear                   untrack all current processes
    help                    display this menu
    kill <process-id>       terminate the specified process
    list                    display all processes
    show <process-id>       show information on the specified process"

LISTFMT="%-15s%-30s%-20s%-5s\n"
LISTDIVLEN=72

# load project directory and file configurations
PROJECTDIR="$(pwd)/$(dirname $0)/.."
. $PROJECTDIR/sbin/config.sh

is_pid_running() {
    if ps -p $1 > /dev/null; then
        echo "true"
    else
        echo "false"
    fi
}

# execute command
case "$1" in
    clear)
        cat /dev/null > $PROCFILE
        rm $LOGDIR/*
        ;;
    help)
        printf "$USAGE\n"
        exit 0
        ;;
    kill)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'kill' command requires one argument" && exit 1

        # kill process
        cat $PROCFILE | grep "^$2 " | awk '{print $2}' | xargs kill
        ;;
    list)
        printf "$LISTFMT" "pid" "name" "timestamp" "running"
        printf "%.0s-" $(seq 1 $LISTDIVLEN); printf "\n"

        # iterate over PROCFILE
        while read LINE; do
            ARRAY=($LINE)
            RUNNING=$(is_pid_running ${ARRAY[1]})
            printf "$LISTFMT" "${ARRAY[0]}" \
                "${ARRAY[3]}" "${ARRAY[2]}" "$RUNNING"
        done < $PROCFILE
        ;;
    show)
        LINE=$(cat $PROCFILE | grep "^$2 ")
        if [ ! -z "$LINE" ]; then
            ARRAY=($LINE)
            RUNNING=$(is_pid_running ${ARRAY[1]})

            echo "{ \"pid\" : \"${ARRAY[0]}\", \"ospid\" : \"${ARRAY[1]}\", \"name\" : \"${ARRAY[3]}\", \"timestamp\" : \"${ARRAY[2]}\", \"running\" : \"$RUNNING\", \"options\" : \"${ARRAY[4]}\" }"
        fi
        ;;
    *)
        printf "$USAGE\n"
        exit 1
        ;;
esac
