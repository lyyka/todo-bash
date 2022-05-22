#!/usr/bin/bash

#
# Global variables
#
PATH_TO_LISTS_FOLDER="./lists"
CREATED_LISTS=()

source './colors.sh'
source './utils.sh'

# Make sure lists directory exists
if [[ ! -d $PATH_TO_LISTS_FOLDER ]]; then
    mkdir "$PATH_TO_LISTS_FOLDER"
fi

#
# Universal separator
#
print_separator() {
    echo '----------------------'
}

#
# Load all lists
#
load_list_names_into_memory() {
    for file in "$PATH_TO_LISTS_FOLDER"/*_todo_bash.list; do
        local filename="$(basename "$file")"
        if [[ $filename != "*" ]]; then
            CREATED_LISTS+=("$filename")
        fi
    done
}

#
# Print menu with "new" option & list of lists
#
print_menu() {
    print_in_color $PURPLE "To-do list app"
    print_separator

    local menuCounter=1

    print_in_color $GREEN "$menuCounter) New list"

    if [[ ${#CREATED_LISTS[@]} > 0 ]]; then
        print_separator
        for i in "${!CREATED_LISTS[@]}"; do
            let "menuCounter += 1"
            echo "$menuCounter) ${CREATED_LISTS[$i]}"
        done
    fi

    print_separator
}


#
# Program starts here
#
clear
load_list_names_into_memory
print_menu
read -s