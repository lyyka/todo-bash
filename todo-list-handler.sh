#!/usr/bin/bash

#
# Global variables
#
TODOS=()
CHECKED=()
SELECTED_ITEM_INDEX=-1
INPUT_MODE_ACTIVE=0
REPO_URL=https://github.com/lyyka/todo-bash
SAVE_FILENAME="$(hostname)_todo_bash.data"

# Load saved file
if [[ -f "$SAVE_FILENAME" ]]; then
    source "$SAVE_FILENAME"
fi

source "./colors.sh"
source "./utils.sh"

#
# Save state of relevant variables in a file
#
save_variables() {
    local filename="$SAVE_FILENAME"

    # Clear any previous saves
    echo > "$filename"
  
    printf -v joinedTodos "'%s' " "${TODOS[@]}"
    printf -v joinedChecked "%s " "${CHECKED[@]}"

    echo "TODOS=(${joinedTodos%,})" >> "$filename"
    echo "CHECKED=(${joinedChecked%,})" >> "$filename"
    echo "SELECTED_ITEM_INDEX=$SELECTED_ITEM_INDEX" >> "$filename"
}

#
# Save state of todos in a file
#
save_mode() {
    clear

    print_in_color $PURPLE "---SAVE MODE---"

    save_variables
    echo -e "${GREEN}Saved!$NO_COLOR"

    sleep .7
}

#
# Inline commands below the list
#
print_commands_inline() {
   echo -e "^K - Insert | E - Edit item | ^S - Save all\n^E - Options | ^F - Quit"
}

#
# Display all options and commands
#
options_mode() {
    clear
    print_in_color $PURPLE "---OPTIONS & COMMANDS---"
    print_separator
    echo "^K - Open insert mode to add new item"
    echo "E - Edit currently selected item"
    echo "ENTER - Mark currently selected item as resolved"
    echo "DELETE / BACKSPACE - Delete currently selected item"
    echo "^E - Open options & commands menu"
    echo "^S - Save state to a file to be loaded on next run"
    echo "^F - Quit with confirmation prompt"
    print_separator
    echo "<- Press ENTER to go back"
    read -s
}

#
# Welcome text printed when script is run for the firs time
#
print_welcome_text() {
    echo 'Welcome to to-do list created in bash!'
    echo 'You can create, toggle, save & delete to-do items from your terminal'
    echo "Repository: $REPO_URL"
    print_separator
}

#
# When no todo items are present
#
print_empty_state() {
    print_in_color $PURPLE "No to-dos added!"
    print_separator
    print_commands_inline
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
        echo -e "${prefix} ${color} [${checkboxContent}] ${TODOS[$1]} ${NO_COLOR}"
    fi
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
        print_separator
        print_commands_inline
    fi
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
    print_in_color $PURPLE "---INPUT MODE---"
    print_separator
    read -e -p "$(echo -e "${GREEN}New item:${NO_COLOR} ")" newItem
    if [[ ! -z "$newItem" ]]; then # prevent empty values from being added
        add_todo "$newItem"
    fi
}

#
# Display edit page for the item
#
edit_item_mode() {
    clear
    print_in_color $PURPLE "---EDIT MODE---"
    local item="${TODOS[$1]}"
    read -e -p "$(echo -e "${GREEN}New text:${NO_COLOR} ")" -i "$item" item
    TODOS[$1]="$item"
}

#
# Confirm quitting
#
confirm_exit() {
    clear
    read -p "Save before closing [y\n]? (y) - " answer

    if [[ $answer == "y" || $answer == "Y" || -z $answer ]]; then
        save_variables
        echo -e "${GREEN}Saved!${NO_COLOR}"
    fi

    exit
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
    local options_mode_char=$(printf "\x05") # ^E
    local save_mode_char=$(printf "\x13") # ^S
    local edit_selected_item_char='e' # e

    read -sn1 mode

    if [[ $mode == $enter_char && $SELECTED_ITEM_INDEX > -1 ]]; then
        toggle_todo $SELECTED_ITEM_INDEX
    elif [[ $mode == $delete_char && $SELECTED_ITEM_INDEX > -1 ]]; then
        delete_todo $SELECTED_ITEM_INDEX
    elif [[ $mode == $quit_char ]]; then
        confirm_exit
    elif [[ $mode == $arrow_up_char ]]; then
        move_indicator_up
    elif [[ $mode == $arrow_down_char ]]; then
        move_indicator_down
    elif [[ $mode == $input_mode_char ]]; then
        input_mode
    elif [[ $mode == $options_mode_char ]]; then
        options_mode
    elif [[ $mode == $save_mode_char ]]; then
        save_mode
    elif [[ $mode == $edit_selected_item_char ]]; then
        edit_item_mode $SELECTED_ITEM_INDEX
    fi 
}

#
# Script start
#

stty -ixon # Disable ctrl + s combo while the script is running

clear # Clear screen for start

print_welcome_text # Print welcome text


# Loop until script is closed through confirmation promp or manually
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
