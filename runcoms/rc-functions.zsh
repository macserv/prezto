#
# Defines all user-created functions for shell commands
#


################################################################################
#  SHARED / HELPERS

#
#  Echo a log message with consistent formatting, including tracing info and
#  a message prefix based on the severity of the message.
#  
#  $1: The message to be logged.
#  $2: The log type.  This is optional, and can be any of the following.
#      The message prefix is demonstrated to the right of the log type name.
#
#      ERROR    | "[ERROR] <message>"
#      WARNING  | "[WARNING] <message>"
#      INFO     | "[INFO] <message>"
#      DEBUG    | "[DEBUG] <message>"
#      <custom> | "[<custom>] <message>"
#      (none)   | "<message>"
#
#  The tracing info contains the following three pieces of information:
#
#      * The base name of the script being executed.
#            * If `echo_log` is invoked on the command line, this will be the
#              name of the shell (e.g. 'zsh').
#            * If `echo_log` is invoked from within a function created on the
#              command line, this will be empty.
#      * The line number of the `echo_log` statement within the script.
#            * If `echo_log` is invoked on the command line, this represents
#              the history event of the command.
#      * The function within which `echo_log` was called.  If function calls
#        are nested, this is the function nearest the top of the stack.
#            * If `echo_log` is invoked within an anonymous function, this will
#              report as '(anon)`.
#
#  Example:
#      function test_logs { echo_log
#                           echo_log '' ERROR
#                           echo_log 'Mark!'
#                           echo_log 'Not great...' WARNING
#                           function { echo_log 'Creepy!' INFO } }
#  Output:
#      % test_logs
#      [logtest.sh:20(test_logs)]
#      [logtest.sh:21(test_logs)] [ERROR]
#      [logtest.sh:22(test_logs)] Mark!
#      [logtest.sh:23(test_logs)] [WARNING] Not great...
#      [logtest.sh:4((anon))] [INFO] Creepy!
#      % echo_log "One more." MANUAL
#      [zsh:2] [MANUAL] One more.
#
function echo_log # <message> <log_type>
{
    case $2 in
        ERROR)   local prefix="[ERROR]"      ;;
        WARNING) local prefix="[WARNING]"    ;;
        INFO)    local prefix="[INFO]"       ;;
        DEBUG)   local prefix="[DEBUG]"      ;;
        *)       local prefix="${2:+[${2}]}" ;;
    esac

    local file=${funcfiletrace[1]##*/}
    local func=${funcstack[2]}
    
    echo "[${file:+"$file"}${func:+"($func)"}]${prefix:+ ${prefix}}${1:+ ${1}}"
}

#
#  Causes a `return` from the current function and echoes a consistently-
#  formatted log message which includes tracing info and an "[ERROR]" prefix.
#
#  $1: The message to be displayed.
#  $2: The status code to be `return`ed from the function.
#
#  A single line...
#
#      eject_warp_core || fail "Ejector systems off-line ($?)!" $?
#
#  ... replaces this...
#
#      eject_warp_core
#      eject_status=$?
#      if [ eject_status -neq 0 ] ; then
#          echo_log "Ejector systems off-line (${eject_status})!" ERROR
#          return $eject_status
#      fi
#
function fail # <message> <status>
{
    local fail_message="${1:-An error ${2:+(${2}) }occurred.}"
    local fail_status=${2:-1}
    
    trap "echo_log ${(qq)fail_message} ERROR ; return ${fail_status}" EXIT

    return ${fail_status}
}


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
    [[ $# -ge 1 ]]  || fail 'Missing input path argument.' 10

    local original_path="$()$1"
    local unique_path="${original_path}"
    local index=0

    while [[ -e $unique_path ]] ; do

        let index++
        unique_path="${original_path:r}-$index.${original_path:e}"

    done

    echo "${unique_path}"
}


