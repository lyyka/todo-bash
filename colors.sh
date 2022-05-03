#
# Color codes
#
PURPLE="\e[1;35m"
GREEN="\e[1;32m"
NO_COLOR="\e[0m"

print_in_color() {
    echo -e "$1$2${NO_COLOR}"
}