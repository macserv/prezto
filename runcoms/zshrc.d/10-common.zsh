#
# Defines all user-created functions for shell commands
#


################################################################################
#  SHARED / HELPERS

#
#  "Comment" a line of text in a way that is visible in a list of commands.
#  This function does nothing, and does not make use of the arguments passed to
#  it.  The arguments are ignored, and can be used to make a general comment.
#
#  This differs from '#' in that comments following '//' will appear in the
#  listing of a function's script as reported by commands like 'which'.
#
#  Example 1:
#      % function comment_hash() { # comment, yo! }
#      function>
#      # The octalthorpe character prevented the closing brace from being
#      # interpreted, and the line editor is waiting for more lines.
#
#  Example 2:
#      % function comment_hash() {
#      function>     # comment, yo!
#      function> }
#      % which comment_hash
#      comment_hash () {
#
#      }
#
#  Example 3:
#      % function comment_slash() { // comment, yo! }
#      % which comment_slash
#      comment_slash () {
#          // comment, yo!
#      }
#
function //() # [comment_word] ...
{
}


#
#  Echo a log message with consistent formatting, including tracing info and
#  a message prefix based on the severity of the message.
#  
#  $1: The message to be logged.  To read this from stdin, use '--'.
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
#      function test_logs() { echo_log
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
#      [-zsh:2] [MANUAL] One more.
#
function echo_log() # <message> <log_type>
{
    local message="${1}"
    
    [[ ${message} == '--' ]] && read -r message
    
    case $2 in
        ERROR)   local prefix="[ERROR]"      ;;
        WARNING) local prefix="[WARNING]"    ;;
        INFO)    local prefix="[INFO]"       ;;
        DEBUG)   local prefix="[DEBUG]"      ;;
        *)       local prefix="${2:+[${2}]}" ;;
    esac

    local   file=${funcfiletrace[1]##*/}
    local   func=${funcstack[2]}
    local output="[${file:+"$file"}${func:+"($func)"}]${prefix:+ ${prefix}}${message:+ ${message}}"
    
    if [[ "${2}" != "ERROR" ]] ; then
        echo "${output}"
    else
        >&2 echo "${output}"
    fi
}



#
#  Prints a consistently-formatted message designed for logging, which
#  includes tracing info and an "[ERROR]" prefix, and then issues an
#  additional `return` command (with the code of your choice) in the
#  environment where `fail` was called.
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
#  As a result of the extra `return` command, if `fail` is called within
#  a function, execution of that function will end, and control will
#  return to the parent environment.  Similarly, if `fail` is used in
#  a "one-liner" list of commands, any subsequent commands will not be
#  executed.  A subshell can be used to allow a one-liner to continue.
#
#    % fail 'Bar' || echo 'Baz'
#    [-zsh:1] [ERROR] Bar
#    % ( fail 'Bar' ) || echo 'Baz'
#    [-zsh:9] [ERROR] Bar
#    Baz#
#  
#  $1: The message to be displayed.
#  $2: The status code to be `return`ed from the function.
#
function fail() # <message> <status>
{
    local fail_message="${1:-An error ${2:+(${2}) }occurred.}"
    local fail_status=${2:-1}
    
    trap "echo_log ${(qq)fail_message} ERROR ; return ${fail_status}"  EXIT

    return
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
function unique_path() # <path>
{
    local original_path=${~"${1}"} ; [[ -n "${original_path}" ]] || fail 'Missing input path argument.' 10
    local   unique_path="${original_path}"
    local         index=0

    while [[ -e $unique_path ]] ; do

        (( index++ ))
        unique_path="${original_path:r}-$index.${original_path:e}"

    done

    echo "${unique_path}"
}


#
#  Replace the contents of target_file with those of source_file, preserving
#  the metadata and modification date of the target_file.
#
function mv_replace() # <source_file> <target_file>
{
    local source_file target_file target_date_modified
    
    source_file=${~"${1}"} ; [[ -n "${source_file}" && -f "${source_file}" ]] || fail 'Argument for source file is missing or empty, or file does not exist.' 10
    target_file=${~"${2}"} ; [[ -n "${target_file}" && -f "${target_file}" ]] || fail 'Argument for target file is missing or empty, or file does not exist.' 11
    
    target_date_modified="$(stat -f "%Sm" -t "%C%y%m%d%H%M.%S" "${target_file}")"
    
    mv    -f       "${source_file}"          "${target_file}" || fail     'Could not replace target file contents with source.' $?
    touch -c -m -t "${target_date_modified}" "${target_file}" || echo_log 'Could not reset target file modification date to pre-operation date.' WARNING
}


#
#   Options:
#       --validate-only : Dry run.  Print matching files without modification.
#
#   Arguments:
#       <description pattern> : Each file specified by <input files> will be
#           scanned by the 'file --brief' command.  If its description matches
#           this pattern, its extension will be checked against the provided
#           list of <"valid extensions">.
#
#       <"valid extensions"> : Space-separated list of valid extensions for
#           files matching the <description pattern>.
#
#       <replacement extension> : The extension which should be appended to
#           files which, according to the above criteria, do not have a valid
#           extension.
#  
#       <input files> : The file, files, or glob to be processed.
#
#   Example:  Add the extension 'jpg' to files (only) WHICH have no extension,
#       AND are identified by the 'file' command as a JPEG file,
#       AND do not have one of the following extensions:
#       'jpg', 'JPG', 'jpeg', or 'JPEG'.
#
#       add_missing_extension_for_file_description \
#           'JPEG*' 'jpg JPG jpeg JPEG' 'jpg' ^*.*(.)
#
function add_missing_extension_for_file_description() # [--validate-only] <description pattern> <"valid extensions"> <replacement extension> <input files>
{
    local validate_only file_command_pattern replacement_extension 
    local -a valid_extensions input_files
    
    [[ "${1}" = '--validate-only' ]] &&
    { 
        echo "Validating only... no modifications will be made."
        validate_only="YES"
        shift
    }
    
    [[ -n "${1}" ]] || fail "Argument for 'file --brief' match pattern is missing or empty" 10
    file_command_pattern="${1}"
    
    shift ; [[ -n "${1}" ]] || fail 'Argument for valid extensions is missing, empty, or not an array' 20
    valid_extensions=( ${(ps: :)1} )
    
    shift ; [[ -n "${1}" ]] || fail "Argument for replacement extension is missing or empty" 30
    replacement_extension="${1}"
    
    shift ; (( ${#@} )) || fail "Input file(s) missing or empty" 40
    input_files=( ${@} )
    
    for input_file ( ${input_files} )
    {
        input_file=${~"${input_file}"}
        
        [[ "$(file --brief ${input_file})" = ${~file_command_pattern} ]] || continue
      
        { [[ -n "${input_file:e}" ]] && (( $valid_extensions[(Ie)${input_file:e}] )) } ||                                  
        {
            echo "WRONG EXTENSION: ${input_file}"
            [[ "${validate_only}" = "YES" ]] || mv ${input_file} "${input_file}.${replacement_extension}"
        }
    }
}


#
#  Recursively remove macOS-specific Finder metadata files, stored as files prefixed with '._'
#
function remove_finder_metadata_files() # [--recursive] [--dryrun]
{
    local working_path remove_cmd file_brief_cmd file_brief_description
    
    working_path='.'
    remove_cmd=(rm -v -f)
    file_brief_cmd=(file --brief)
    file_brief_description="AppleDouble encoded Macintosh file"
    
    [[ "${1}" = '--recursive' ]] && { working_path='**' ; shift ; }
    [[ "${1}" = '--dryrun'    ]] && { remove_cmd='echo' ; }
    
    for macos_file ( ${~"${working_path}"}/._*(.N) )
    { 
        [[ "$( "${file_brief_cmd[@]}" "${macos_file}" )" == "${file_brief_description}" ]] ||
        { 
            echo "Not removing '${macos_file}' because '${file_brief_cmd}' does not describe it as '${file_brief_description}'."
            continue
        }
        
        "${remove_cmd[@]}" "${macos_file}"
    }
}


