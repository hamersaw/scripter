#!/bin/bash

usage() {
    echo "USAGE $(basename $0) [COMMAND]
COMMANDS:
    help
    kill
    list
    show"
}

# initialize variables
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
    help)
        usage
        exit 0
        ;;
    kill)
        # check argument length
        (( $# != 2 )) && \
            echo "the 'kill' command requires one argument" && exit 1

        # kill process
        cat $PROCESSFILE | grep "^$2 " | awk '{print $2}' | xargs kill
        ;;
    list)
        printf "%-15s%-30s%-20s%-5s\n" "pid" "name" "timestamp" "running"
        echo "------------------------------------------------------------------------"

        # iterate over PROCESSFILE
        while read LINE; do
            ARRAY=($LINE)
            RUNNING=$(is_pid_running ${ARRAY[1]})
            printf "%-15s%-30s%-20s%-5s\n" "${ARRAY[0]}" \
                "${ARRAY[3]}" "${ARRAY[2]}" "$RUNNING"
        done < $PROCESSFILE
        ;;
    show)
        LINE=$(cat $PROCESSFILE | grep "^$2 ")
        if [ ! -z "$LINE" ]; then
            ARRAY=($LINE)
            RUNNING=$(is_pid_running ${ARRAY[1]})

            echo "{
    \"pid\" : \"${ARRAY[0]}\"
    \"ospid\" : \"${ARRAY[1]}\"
    \"name\" : \"${ARRAY[3]}\"
    \"timestamp\" : \"${ARRAY[2]}\"
    \"running\" : \"$RUNNING\"
    \"options\" : \"${ARRAY[4]}\"
}"
        fi
        ;;
    *)
        usage
        exit 1
        ;;
esac
