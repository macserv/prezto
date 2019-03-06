#
# Defines all user-created functions for shell commands
#


################################################################################
#  SHARED / HELPERS

# 
#  Determines whether or not a file or directory exists at the given path.
#
#  If no file/folder exists, it will return the path unmodified.
#  If it does exist, it will attempt to generate a unique path by appending an
#  integer to the end, beginning at 1 and incrementing until the path is unique.
#
#  $1: Path to test for uniqueness
#
function unique-path # <path>
{
    [[ $# -ge 1 ]]  || bail 'Missing input path argument.' 10

    local original_path="$()$1"
    local unique_path="${original_path}"
    local index=0

    while [[ -e $unique_path ]] ; do

        let index++
        unique_path="${original_path:r}-$index.${original_path:e}"

    done

    echo "${unique_path}"
}


function bail # <message> <status>
{
    TRAPEXIT() { return $? }

    echo "[ERROR] ${1:-An error occurred.}"
    
    return ${2:-1}
}

