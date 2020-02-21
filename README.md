# scripter
## OVERVIEW
Generalized framework for managing script execution.

## USAGE
#### INSTALLATION
    # initialize scripter directories
    scripter init
#### VARIABLE MANAGEMENT
    # set variable
    scripter var set foo.bar baz

    # list variables
    scripter var list

    # unset variable (and all sub-variables)
    scripter unset foo
#### REPOSITORY MANAGEMENT
    # add scripter repository
    scripter repo add nethammer https://github.com/hamersaw/nethammer

    # update repository
    scripter repo update
#### EXECUTE MODULE
    # view available modules
    scripter mod list

    # show module information
    scripter mod show nethammer/wifi/rouge-ap.sh

    # run module
    scripter var set wifi.interface wlp82s0
    scripter var set wifi.ssid scripter-ap
    scripter mod run-bg nethammer/wifi/rouge-ap.sh
#### PROCESSES MANAGEMENT
    # view running processes
    scripter proc list

    # view process logs
    scripter proc log 12289

    # terminate scripter process
    scripter proc kill 12289

## COMMON ISSUES
1. Program not working when running with 'sudo'.
    # preserve $HOME directory with sudo command
    sudo --preserve-env=HOME scripter ...

## TODO
