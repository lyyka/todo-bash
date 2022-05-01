#!/usr/bin/bash

TODOS=()
CHECKED=()
SELECTED_ITEM_INDEX=-1
INPUT_MODE_ACTIVE=0
REPO_URL=https://github.com/lyyka/todo-bash

PURPLE="\e[1;35m"
GREEN="\e[1;32m"
NO_COLOR="\e[0m"

print_commands_inline() {
   echo '^K - Insert mode | ^F - Quit'
}

print_commands() {
    echo 'Commands:'
    echo '^K - Insert mode'
    echo '^F - Quit'
}

print_welcome_text() {
    echo 'Welcome to to-do list created in bash!\e[0m'
    echo 'You can create, toggle & delete to-do items from your terminal'
    echo "Repository: $REPO_URL"
    echo '----------------------'
    print_commands
    echo '----------------------'
}

#
# Add a todo item to the array
#
add_todo() {
    TODOS+=("$@")
    CHECKED+=(0)
    # Set first ever to-do created as selected on creation
    if [[ ${SELECTED_ITEM_INDEX} == -1 && ${#TODOS[@]} > 0 ]]; then
        SELECTED_ITEM_INDEX=0
    fi
}

#
# Print a todo line
#
print_todo() {
    # Handle checkbox content
    local color=""
    local checkboxContent=" "
    if [[ ${CHECKED[$1]} == 1 ]]; then
        checkboxContent="X"
        color=$GREEN
    fi

    # Handle line prefix (for selection indicator)
    local prefix=""
    if [[ $1 == ${SELECTED_ITEM_INDEX} ]]; then
        prefix="->"
    fi

    # Print the resulting content
    if [[ -z "$color" ]]; then
        echo "${prefix} [${checkboxContent}] ${TODOS[$1]}"
    else
        echo -e "${color} ${prefix} [${checkboxContent}] ${TODOS[$1]} ${NO_COLOR}"
    fi
}

#
# When no todo items are present
#
print_empty_state() {
    echo "No to-dos added!"
    print_commands_inline
}

#
# Print all todos from array
#
print_all_todos() {
    for i in "${!TODOS[@]}"; do
        print_todo $i
    done

    if [[ ${#TODOS[@]} == 0 ]]; then
        print_empty_state
    else
        echo '----------------------'
        print_commands_inline
    fi
}

#
# Rebuilds passed array so the indexes remain continuous
#
rebuild_array() {
    local -n arr=$1
    local tempArray=()
    for i in "${!arr[@]}"; do
        tempArray+=( "${arr[i]}" )
    done
    arr=("${tempArray[@]}")
}

#
# Deletes a specified todo
#
delete_todo() {
    # Remove element from arrays
    unset TODOS[SELECTED_ITEM_INDEX]
    unset CHECKED[SELECTED_ITEM_INDEX]

    # Select first item in the array after deleting
    # Or revert to default -1 value if no items remain present
    if [[ ${#TODOS[@]} > 0 ]]; then
        SELECTED_ITEM_INDEX=0
    else
        SELECTED_ITEM_INDEX=-1
    fi

    rebuild_array TODOS
    rebuild_array CHECKED
}

#
# Toogle specific todo by index.
# What it does is actually removes the todo and moves it to the back of the array and then checks it
# For already checked items, just unchecks them
#
toggle_todo() {
    if [[ ${CHECKED[$1]} == 1 ]]; then
        CHECKED[$1]=0
    else
        local item=${TODOS[$1]} # save in temp var
        delete_todo $1 # delete from current pos
        add_todo "$item" # re-add at the back
        local last_index=${#TODOS[@]}-1
        CHECKED[last_index]=1 # check the last item (this one)
    fi
}

#
# Handle `selected` value to not go out of array range
#
handle_selected_index_out_of_range() {
    if [[ $SELECTED_ITEM_INDEX == ${#TODOS[@]} ]]; then
        SELECTED_ITEM_INDEX=0
    elif [[ $SELECTED_ITEM_INDEX < 0 ]]; then
        SELECTED_ITEM_INDEX=$((${#TODOS[@]}-1))
    fi
}

#
# Change selected item up
#
move_indicator_up() {
    let "SELECTED_ITEM_INDEX -= 1"
    handle_selected_index_out_of_range
}

#
# Change selected item down
#
move_indicator_down() {
    let "SELECTED_ITEM_INDEX += 1"
    handle_selected_index_out_of_range
}

#
# Display and handle input mode
#
input_mode() {
    clear
    read -p 'Item name: ' newItem
    if [[ ! -z "$newItem" ]]; then # prevent empty values from being added
        add_todo "$newItem"
    fi
}

#
# Confirm quitting
#
confirm_exit() {
    clear
    read -p "All todos will be lost. Are you sure? [y/n] - " answer
    if [[ $answer == "y" || $answer == "Y" ]]; then
        exit
    fi
}

#
# Handle keypress from keyboard
#
handle_keyboard_input() {
    local enter_char=$(printf "\x0a") # ENTER
    local delete_char=$(printf "\x7f") # DEL
    local arrow_up_char=$(printf "\x41") # [A
    local arrow_down_char=$(printf "\x42") # [B
    local quit_char=$(printf "\x06") # ^F
    local input_mode_char=$(printf "\x0b") # ^K

    read -sn1 mode
    
    if [[ $mode == $enter_char && $SELECTED_ITEM_INDEX > -1 ]]; then
        toggle_todo SELECTED_ITEM_INDEX
    elif [[ $mode == $delete_char && $SELECTED_ITEM_INDEX > -1 ]]; then
        delete_todo SELECTED_ITEM_INDEX
    elif [[ $mode == $quit_char ]]; then
        confirm_exit
    elif [[ $mode == $arrow_up_char ]]; then
        move_indicator_up
    elif [[ $mode == $arrow_down_char ]]; then
        move_indicator_down
    elif [[ $mode == $input_mode_char ]]; then
        input_mode
    fi 
}

clear

print_welcome_text

while true
do
    if [[ $INPUT_MODE_ACTIVE == 1 ]]; then
        input_mode
        INPUT_MODE_ACTIVE=0
    else
        print_all_todos
        handle_keyboard_input
    fi
    
    clear
done
