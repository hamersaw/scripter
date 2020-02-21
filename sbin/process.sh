#!/bin/bash

usage="usage $(basename $0) <COMMAND>
COMMANDS:
    clear                   untrack all current processes
    help                    display this menu
    kill <process-id>       terminate the specified process
    list                    display all processes
    log <process-id>        view specified process logs
    show <process-id>       show information on the specified process"
listfmt="\e[1;34m%-15s\e[1;32m\e[1;22m%-30s\e[1;35m%-23s\e[1;36m%-5s\e[m\n"
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
        cat /dev/null >$procfile 
        rm $logdir/* >/dev/null 2>&1

        printf "$(success "[-] cleared process cache\n")"
        ;;
    help)
        echo "$usage"
        ;;
    kill)
        # check argument length
        (( $# != 2 )) && printf \
            "$(fail "'kill' requires one argument\n")" && exit 1

        # kill process
        cat $procfile | grep "^$2 " | awk '{print $2}' \
            | xargs kill >/dev/null 2>&1

        if [ $? -eq 0 ]; then
            printf "$(success "[-] process '$2' terminated\n")"
        else
            printf "$(warn "[0] unable to terminate process '$2'\n")"
        fi
        ;;
    list)
        printf "$listfmt" "pid" "name" "timestamp" "running"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"

        # iterate over procfile
        while read line; do
            array=($line)
            running=$(is_pid_running ${array[1]})
            printf "$listfmt" "${array[0]}" \
                "${array[3]}" "${array[2]}" "$running"
        done <$procfile
        ;;
    log)
        # check argument length
        (( $# != 2 )) && printf \
            "$(fail "'log' requires one argument\n")" && exit 1

        # print log directory
        if [ -f $logdir/$2.log ]; then
            cat $logdir/$2.log
        else
            printf "$(warn "[0] log file for pid '$2' not found\n")"
        fi
        ;;
    show)
        # check argument length
        (( $# != 2 )) && printf \
            "$(fail "'show' requires one argument\n")" && exit 1

        line=$(cat $procfile | grep "^$2 ")
        if [ ! -z "$line" ]; then
            array=($line)
            running=$(is_pid_running ${array[1]})

            echo "{ \"pid\" : \"${array[0]}\", \"ospid\" : \"${array[1]}\", \"name\" : \"${array[3]}\", \"timestamp\" : \"${array[2]}\", \"running\" : \"$running\", \"options\" : \"${array[@]:4}\" }" | jq
        fi
        ;;
    *)
        echo "$usage"
        exit 1
        ;;
esac
