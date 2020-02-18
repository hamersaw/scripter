#!/bin/bash

usage="usage $(basename $0) <COMMAND>
COMMANDS:
    help                    display this menu
    list                    display available modules
    run <module-name>       run the specified module
    run-bg <module-name>    run the specified module in the background
    show <module-name>      show information on the specified module"
listfmt="%-35s%-50s\n"
listdivlen=90

parse_module() {
    # check if file exists
    [ ! -f $1 ] && return 1

    # read file config
    local config=""
    while read line; do
        case $line in
            \#*) config+="${line:1}" ;;
            *) break ;;
        esac
    done < <(tail -n +2 $1)

    # set module variables
    module_name=${1/$moddir/} # TODO - remove leading '/'
    local description=$(echo $config | jq '.description')
    module_description=$(echo "$description" | sed 's/\"//g')
    module_config="$config"
    return 0
}

parse_module_config() {
    module_option_names=()
    module_option_flags=()
    module_option_required=()

    option_count=$(echo "$1" | jq '.options | length')
    for (( i=0; i<option_count; i++ )); do
        local option_config=$(echo "$1" | jq ".options[$i]")

        local name=$(echo $option_config | jq '.name')
        module_option_names+=( $(echo "$name" | sed 's/\"//g') )
        local flag=$(echo $option_config | jq '.flag')
        module_option_flags+=( $(echo "$flag" | sed 's/\"//g') )
        local required=$(echo $option_config | jq '.required')
        module_option_required+=( $(echo "$required" | sed 's/\"//g') )
    done

    return 0
}

# execute command
case "$1" in
    help)
        echo "$usage"
        ;;
    list)
        printf "$listfmt" "name" "description"
        printf "%.0s-" $(seq 1 $listdivlen); printf "\n"

        for module in $(find $moddir -not -path "$moddir/*/\.git/*" \
                -type f -executable | sort); do
            # parse module
            parse_module "$module"
            [ $? -ne 0 ] && echo "failed to parse module" && continue

            # print module
            printf "$listfmt" "$module_name" "$module_description"
        done
        ;;
    run)
        # check argument length
        (( $# != 2 )) && echo "'run' requires one argument" && exit 1

        # set foreground to true
        foreground="true"
        ;&
    run-bg)
        # check argument length
        (( $# != 2 )) && echo "'run-bg' requires one argument" && exit 1

        # if unset -> set foreground to false
        [ -z "$foreground" ] && foreground="false"

        # parse module
        parse_module "$moddir/$2"
        [ $? -ne 0 ] && echo "failed to parse module" && exit 1

        # parse options
        parse_module_config "$module_config"
        [ $? -ne 0 ] && echo "failed to parse module config" && exit 1

        # populate options
        for (( i=0; i<${#module_option_names[@]}; i++ )); do
            # retrieve variable
            value=$($scriptdir/variable.sh get ${module_option_names[$i]})

            # check if variable is set and required
            if [ -z "$value" ]; then
                if [ "${module_option_required[$i]}" = "true" ]; then
                    echo "required variable '${module_option_names[$i]}' is not set"
                    exit 1
                else
                    continue;
                fi
            fi

            # append to optionstring
            if [ -z "$optionstring" ]; then
                optionstring="-${module_option_flags[$i]} $value"
            else
                optionstring+=" -${module_option_flags[$i]} $value"
            fi
        done

        # execute module
        modulefile="$moddir/$2"
        case $foreground in
            true)
                $modulefile "$optionstring"
                ;;
            false)
                # execute in background
                pid="$RANDOM"
                $modulefile "$optionstring" >$logdir/$pid.log 2>&1 &

                echo "$pid $! $(date +%Y.%m.%d-%H:%M:%S) $2 $optionstring" \
                    >> $procfile
                echo "executed process with pid $pid"
                ;;
        esac
        ;;
    show)
        # check argument length
        (( $# != 2 )) && echo "'show' requires one argument" && exit 1
            
        # parse module
        parse_module "$moddir/$2"
        [ $? -ne 0 ] && echo "failed to parse module" && exit 1

        # print module
        echo "$module_config" | jq
        ;;
    *)
        printf "$usage\n"
        exit 1
        ;;
esac
