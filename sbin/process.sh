#!/bin/bash

usage="usage $(basename $0) <COMMAND>
COMMANDS:
    clear                   untrack all current processes
    help                    display this menu
    kill <process-id>       terminate the specified process
    list                    display all processes
    show <process-id>       show information on the specified process"
listfmt="%-15s%-30s%-23s%-5s\n"
listdivlen=75

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
        cat /dev/null > $procfile
        rm $logdir/*
        ;;
    help)
        echo "$usage"
        ;;
    kill)
        # check argument length
        (( $# != 2 )) && \
            echo "'kill' requires one argument" && exit 1

        # kill process
        cat $procfile | grep "^$2 " \
            | awk '{print $2}' | xargs kill
        ;;
    list)
        printf "$listfmt" "pid" "name" "timestamp" "running"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"

        # iterate over procfile
        while read LINE; do
            array=($LINE)
            running=$(is_pid_running ${array[1]})
            printf "$listfmt" "${array[0]}" \
                "${array[3]}" "${array[2]}" "$running"
        done < $procfile
        ;;
    show)
        LINE=$(cat $procfile | grep "^$2 ")
        if [ ! -z "$LINE" ]; then
            array=($LINE)
            running=$(is_pid_running ${array[1]})

            echo "{ \"pid\" : \"${array[0]}\", \"ospid\" : \"${array[1]}\", \"name\" : \"${array[3]}\", \"timestamp\" : \"${array[2]}\", \"running\" : \"$running\", \"options\" : ${array[4]} }" | jq
        fi
        ;;
    *)
        echo "$usage"
        exit 1
        ;;
esac
