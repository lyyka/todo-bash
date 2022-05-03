#
# Universal separator
#
print_separator() {
    echo '----------------------'
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