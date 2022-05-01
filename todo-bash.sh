#!/usr/bin/bash

todos=()
checked=()
selected=-1
inputModeOn=0

print_commands_inline() {
   echo '^K - Insert mode'
}

print_commands() {
    echo 'Commands:'
    echo '^K - Insert mode'
}

print_welcome_text() {
    echo 'Welcome to to-do list created in bash!'
    echo 'You can create, toggle & delete to-do items from your terminal'
    echo 'Repository: ???'
    echo '----------------------'
    print_commands
    echo '----------------------'
}

#
# Add a todo item to the array
#
add_todo() {
    todos+=("$@")
    checked+=(0)
    # Set first ever to-do created as selected on creation
    if [[ ${selected} == -1 && ${#todos[@]} > 0 ]]; then
        selected=0
    fi
}

#
# Print a todo line
#
print_todo() {
    # Handle checkbox content
    local checkboxContent=" "
    if [[ ${checked[$1]} == 1 ]]; then
        checkboxContent="X"
    fi

    # Handle line prefix (for selection indicator)
    local prefix=""
    if [[ $1 == ${selected} ]]; then
        prefix="--->"
    fi

    # Print the resulting content
    echo "${prefix} [${checkboxContent}] ${todos[$1]}"
}

print_empty_state() {
    echo "No to-dos added!"
    print_commands_inline
}

#
# Print all todos from array
#
print_all_todos() {
    for i in "${!todos[@]}"; do
        print_todo $i
    done

    if [[ ${#todos[@]} == 0 ]]; then
        print_empty_state
    fi
}

#
# Deletes a specified todo
#
delete_todo() {
    # Remove element from todo list
    unset todos[selected]
    unset checked[selected]

    # Handle value for `selected` var
    if [[ ${#todos[@]} > 0 ]]; then
        selected=0
    else
        selected=-1
    fi

    # Rebuild to-dos & checked arrays so indexes remain continuous
    local tempT=()
    for i in "${!todos[@]}"; do
        tempT+=( "${todos[i]}" )
    done
    todos=("${tempT[@]}")

    local tempS=()
    for i in "${!checked[@]}"; do
        tempS+=( "${checked[i]}" )
    done
    checked=("${tempS[@]}")
}

#
# Toogle specific todo by index
#
toggle_todo() {
    checked[$1]=$(( 1 - checked[$1] ))
}

#
# Handle `selected` value to not go out of array range
#
handle_selected_index_out_of_range() {
    if [[ $selected == ${#todos[@]} ]]; then
        selected=0
    elif [[ $selected < 0 ]]; then
        selected=$((${#todos[@]}-1))
    fi
}

#
# Change selected item up
#
move_indicator_up() {
    let "selected -= 1"
    handle_selected_index_out_of_range
}

#
# Change selected item down
#
move_indicator_down() {
    let "selected += 1"
    handle_selected_index_out_of_range
}

#
# Display and handle input mode
#
input_mode() {
    clear
    read -p 'Item name: ' newItem
    add_todo "$newItem"
}

#
# Handle keypress from keyboard
#
handle_keyboard_input() {
    local enter_char=$(printf "\x0a") # ENTER
    local delete_char=$(printf "\x7f") # DEL
    local arrow_up_char=$(printf "\x41") # [A
    local arrow_down_char=$(printf "\x42") # [B
    local input_mode_char=$(printf "\x0b") # ^K

    read -sn1 mode
    
    if [[ $mode == $enter_char && $selected > -1 ]]; then
        toggle_todo selected
    elif [[ $mode == $delete_char && $selected > -1 ]]; then
        delete_todo selected
    elif [[ $mode == $arrow_up_char ]]; then
        move_indicator_up
    elif [[ $mode == $arrow_down_char ]]; then
        move_indicator_down
    elif [[ $mode == $input_mode_char ]]; then
        input_mode
    fi 
}

clear

# print_welcome_text

while true
do
    if [[ $inputModeOn == 0 ]]; then
        print_all_todos
    else
        input_mode
    fi

    handle_keyboard_input
    
    clear
done
