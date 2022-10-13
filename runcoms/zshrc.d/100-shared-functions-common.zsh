#
# ZSHRC EXTENSION:
# Functions: Common
#


################################################################################
#  SHARED / HELPERS

####
##  "Comment" a line of text in a way that is visible in a list of commands.
##  This function does nothing, and does not make use of the arguments passed to
##  it.  The arguments are ignored, and can be used to make a general comment.
##
##  This differs from '#' in that comments following '//' will appear in the
##  listing of a function's script as reported by commands like 'which'.
##
##  Example 1:
##      % function comment_hash() { # comment, yo! }
##      function>
##      # The octalthorpe character prevented the closing brace from being
##      # interpreted, so zle is now expecting more lines.
##
##  Example 2:
##      % function comment_hash() {
##      function>     # comment, yo!
##      function> }
##      % which comment_hash
##      comment_hash () {
##
##      }
##
##  Example 3:
##      % function comment_slash() { // comment, yo! }
##      % which comment_slash
##      comment_slash () {
##          // comment, yo!
##      }
##
function //() # [comment_word] ...
{
    # Function intentionally empty.
}


####
##  Echo a log message with consistent formatting, including tracing info and
##  a message prefix based on the severity of the message.
##
##  OUTPUT FILE DESCRIPTOR:
##      Messages generated by 'echo_log' are sent to 'stderr' so that they do
##      not interfere with the functionality of functions which print text
##      to 'stdout' which is intended for consumption by a calling function.
##
##  OPTIONS:
##      --transparent : Make the caller transparent; that is, ignore the calling
##          function, and report its parent instead.  This is useful when you want
##          to "transparently" wrap `echo_log` in another logging function without
##          it being displayed as the caller.
##
##  $1 : <message> Required.  The message to be logged.
##       To read this from stdin, use '--'.
##  $2 : [log_type] Optional. Can be any of the following.
##       The message prefix is demonstrated to the right of the log type name.
##
##          ERROR    : "[ERROR] <message>"
##          WARNING  : "[WARNING] <message>"
##          INFO     : "[INFO] <message>"
##          DEBUG    : "[DEBUG] <message>"
##          <custom> : "[<custom>] <message>"
##          (none)   : "<message>"
##
##  $3 : [indent] Optional.  The number of characters which the message should
##      be indented.  Default: no indent.
##  $4 : [fill] Optional.  The string which will be repeated to fill the
##      indented space.  Default: spaces will be used as fill.
##  $5 : [spacer] Optional.  A string which will replace the filler immediately
##      before the message.  Default: none.
##
##  The tracing info contains the following three pieces of information:
##
##      * The base name of the script being executed.
##            * If `echo_log` is invoked on the command line, this will be the
##              name of the shell (e.g. 'zsh').
##            * If `echo_log` is invoked from within a function created on the
##              command line, this will be empty.
##      * The line number of the `echo_log` statement within the script.
##            * If `echo_log` is invoked on the command line, this represents
##              the history event of the command.
##      * The function within which `echo_log` was called.  If function calls
##        are nested, this is the function nearest the top of the stack.
##            * If `echo_log` is invoked within an anonymous function, this will
##              report as `(anon)` (as of zsh 5.8.1).
##
##  SUPPRESSING TRAILING NEWLINE:
##      The log message will end with a newline ('\n') character, causing a
##      line feed and carriage return after printing.  To prevent this default
##      behavior, a '\c' (escape) character can be added to the end of the
##      specified message string, which will suppress the addition of the
##      newline, allowing more characters to be added to the same line.
##
##  EXAMPLE:
##
##      function test_logs()
##      {
##          echo_log
##          echo_log '' INFO
##          echo_log 'Info message.' INFO
##          echo_log 'Warning message.' WARNING
##          echo_log 'Error message!' ERROR
##          echo_log 'Top level debug message.' DEBUG
##          echo_log 'Second level debug without newline... \c' DEBUG 4
##          echo     'ding!' 1>&2
##          echo_log 'Third level debug with dash fill and final space.' DEBUG 8 '-' ' '
##          echo_log 'Third level debug with space fill and final arrow.' DEBUG 8 ' ' '-> '
##          echo_log 'Fourth level debug with alternating dots and spaces.' DEBUG 12 '. '
##          echo_log 'Fifth level debug with dots in groups of three.' DEBUG 16 '... '
##          function { echo_log 'Anonymous invocation with custom 'HACK' log type.' HACK }
##          echo "Message from stdin with custom 'PASS' type." | echo_log -- PASS
##          echo 1>&2
##      }
##
##  EXAMPLE OUTPUT (after copying the above function):
##
##      % pbpaste >! $TMPDIR/logtest.zsh
##      % source $TMPDIR/logtest.zsh
##      % test_logs
##      [logtest.zsh:3(test_logs)]
##      [logtest.zsh:4(test_logs)] [INFO]
##      [logtest.zsh:5(test_logs)] [INFO] Info message.
##      [logtest.zsh:6(test_logs)] [WARNING] Warning message.
##      [logtest.zsh:7(test_logs)] [ERROR] Error message!
##      [logtest.zsh:8(test_logs)] [DEBUG] Top level debug message.
##      [logtest.zsh:9(test_logs)] [DEBUG]     Second level debug without newline... ding!
##      [logtest.zsh:10(test_logs)] [DEBUG] ------- Third level debug with dash fill and final space.
##      [logtest.zsh:11(test_logs)] [DEBUG]      -> Third level debug with space fill and final arrow.
##      [logtest.zsh:12(test_logs)] [DEBUG] . . . . . . Fourth level debug with alternating dots and spaces.
##      [logtest.zsh:13(test_logs)] [DEBUG] ... ... ... ... Fifth level debug with dots in groups of three.
##      [logtest.zsh:14((anon))] [HACK] Anonymous invocation with custom HACK log type.
##      [logtest.zsh:15(test_logs)] [PASS] Message from stdin with custom 'PASS' type.
##
##      % echo_log "Direct invocation on command line with custom 'OK' type." OK
##      [-zsh:4] [OK] Direct invocation on command line with custom 'OK' type.
##
function echo_log() # [--transparent] <message> [log_type] [indent] [fill] [spacer]
{
    typeset -i transparent=0
    [[ "${1}" == "--transparent" ]] && { transparent=1 ; shift ; }

    typeset message="${1}"
    [[ "${message}" == '--' ]] && read -r message

    typeset prefix
    case $2 in
        ERROR)   prefix="[ERROR]"      ;;
        WARNING) prefix="[WARNING]"    ;;
        INFO)    prefix="[INFO]"       ;;
        DEBUG)   prefix="[DEBUG]"      ;;
        *)       prefix="${2:+[${2}]}" ;;
    esac

    typeset -i indent=$3
    (( indent )) &&
    {
        typeset -i message_length=$(( ${#message} + ${indent} ))
        typeset filler="${4:- }"
        typeset spacer="$5"

        [[ -n "$spacer" ]] &&
            { message=${(pl:$message_length::$filler::$spacer:)message} ; } ||
            { message=${(pl:$message_length::$filler:)message} ; }
    }

    typeset -i file_trace_index=1
    typeset -i func_stack_index=2

    # Workaround for issue which causes an entry to be added to the top of the
    # file trace when an anonymous function calls 'echo_log' from a function
    # within a file which has been 'source'd, not executed directly.
    [[ "${funcfiletrace[$file_trace_index]}" == ':'* ]] && { file_trace_index+=1 }

    # If the '--transparent' flag is set, look one index higher in the stack
    # and file trace arrays to functionally ignore the caller.
    (( transparent )) &&
    {
        file_trace_index+=1
        func_stack_index+=1
    }

    typeset file=${funcfiletrace[$file_trace_index]##*/}
    typeset func=${funcstack[$func_stack_index]}

    typeset output="[${file:+"$file"}${func:+"($func)"}]${prefix:+ ${prefix}}${message:+ ${message}}"

    echo "${output}" 1>&2
}


####
##  Echo a debug message, using the 'echo_log' mechanism, which will only be
##  printed if debug echo is enabled (see GLOBAL PARAMETERS).
##
##  The log type will be set to '[DEBUG]', and the '--transparent' flag will be
##  enabled automatically.
##
##  GLOBAL PARAMETERS:
##      ${ENABLE_ECHO_DEBUG}: This parameter must be set to an integer greater
##          than zero for messages to be printed to the console.
##
##  $1 : <message> Required.  The message to be logged.
##       To read this from stdin, use '--'.
##  $2 : [indent] Optional.  The number of characters which the message should
##      be indented.  Default: no indent.
##  $3 : [fill] Optional.  The string which will be repeated to fill the
##      indented space.  Default: spaces will be used as fill.
##  $4 : [spacer] Optional.  A string which will replace the filler immediately
##      before the message.  Default: none.
##
##  NOTE: Refer to the documentation for 'echo_log' for more information
##        about this function's output.
##
function echo_debug() # <message> [indent] [fill] [spacer]
{
    (( ENABLE_ECHO_DEBUG )) || return

    typeset message="${1}"

    [[ "${message}" == '--' ]] && read -r message

    echo_log --transparent "${message}" DEBUG "$2" "$3" "$4"
}


####
##  Print a consistently-formatted message designed for logging, which
##  includes tracing info and an "[ERROR]" prefix.  Then, issue an
##  additional `return` command (with customizable status code) in the
##  environment where `fail` was called.
##
##  This single line...
##
##      eject_warp_core || fail "Ejector systems off-line ($?)." $?
##
##  ... is equivalent to this...
##
##      eject_warp_core
##      eject_status=$?
##      if [ eject_status -neq 0 ] ; then
##          echo_log "Ejector systems off-line (${eject_status})." ERROR
##          return $eject_status
##      fi
##
##  As a result of the extra `return` command, if `fail` is called within
##  a function, execution of that function will end, and control will
##  return to the parent environment.  Similarly, if `fail` is used in
##  a "one-liner" list of commands, any subsequent commands will not be
##  executed.  A subshell can be used to allow a one-liner to continue.
##
##    % fail 'Bar' || echo 'Baz'
##    [-zsh:1] [ERROR] Bar
##    % ( fail 'Bar' ) || echo 'Baz'
##    [-zsh:9] [ERROR] Bar
##    Baz#
##
##  $1 : [message] Optional.  The message to be displayed.
##  $2 : [message] Optional.  The status code to be returned by the function.
##
function fail() # [message] [status]
{
    typeset fail_message="${1:-An error ${2:+(${2}) }occurred.}"
    typeset fail_status=${2:-1}

    trap "echo_log ${(qq)fail_message} ERROR ; return ${fail_status}"  EXIT

    return
}


####
##  Present a GUI alert with a single button to let the user know that
##  an error has occurred.
##
##  $1 : [message] Optional.  The "message" to be shown in the alert.
##  $2 : [title] Optional.  The alert title.  Default: "An error occurred".
##  $3 : [button_label] Optional.  The button label.  Default: "OK".
##
##  The function will print the title of the button which was clicked, e.g.:
##  "buttonReturned:OK"
##
##  Examples:
##      alert_dialog 'Nothing too serious'
##      alert_dialog 'You do not have the correct permissions to do this.' \
##                   'Could not create user'
##      alert_dialog 'KLINGONS OFF THE STARBOARD BOW, CAPTAIN' \
##                   'RED ALERT' \
##                   'BATTLE STATIONS'
##
function display_alert_dialog() # <message> <title> <button_label>
{
    typeset message="$1"
    typeset title="${2:-An error occurred.}"
    typeset button_label="${3:-OK}"

    echo_debug "Displaying alert dialog to user with title: '${title}' / '${message}' / [${button_label}]"

    /usr/bin/osascript 2>/dev/null <<EOAPPLESCRIPT

        tell application "System Events"
            tell process "SystemUIServer"
                display alert "$title" as critical \
                    message "$message" \
                    buttons { "$button_label" } \
                    default button "$button_label"
            end tell
        end tell

EOAPPLESCRIPT
}


####
##  Present a GUI selection user interface to allow the user to choose from a
##  list of available options.
##
##  $1 : [title]  The list title.
##  $2 : [message]  The message prompting to select an item.
##  $3-$n : [item] ... The items which will appear in the list.
##
##  The function will print the item which was selected.
##
##  Return Codes:
##      0: An item was chosen normally.
##      1: The "Cancel" button was clicked.
##
function select_from_list_dialog() # [title] [message] [item] ...
{
    typeset title="$1"
    typeset message="$2"
    typeset -a items=( ${@:3} )
    typeset -a quoted_items=${(j[, ])${(qqq)items[@]}}

    echo_debug "Displaying alert dialog to user: '${title}' / '${message}' / [ ${quoted_items} ]"

    typeset selected_item ; selected_item=$( /usr/bin/osascript 2>/dev/null <<EOAPPLESCRIPT

        tell application "System Events"
            tell process "SystemUIServer"
                activate
                set listOptions to { $quoted_items }
                choose from list listOptions \
                    with title "$title" \
                    with prompt "$message" \
                    OK button name "OK" \
                    cancel button name "Cancel"
            end tell
        end tell

EOAPPLESCRIPT
    )

    [[ "${selected_item}" == "false" ]] && return 1

    echo "${selected_item}"
}


####
##  Silently determine if a user is a member of a given group.
##
##  $1: The name of the user to be verified.
##  $2: The group which is to be checked for membership.
##
##  Return Codes:
##        0: The user is a member of the given group.
##      121: Argument for user name is missing or empty.
##      122: Argument for group name is missing or empty.
##        n: The user is not a member of the given group, or the membership
##           check failed, `dseditgroup` code returned.
##
function check_user_for_group_membership() # <user_name> <group_name>
{
    typeset user_name="${1}"  ; [[ -n "${user_name}"  ]] || return 121
    typeset group_name="${2}" ; [[ -n "${group_name}" ]] || return 122

    echo_debug "Checking whether '${user_name}' is a member of '${group_name}'..."
    /usr/sbin/dseditgroup -o checkmember -m "${user_name}" "${group_name}" >/dev/null
}


####
##  Silently attempt to add a user to the specified group.
##
##  $1: The name of the user to be added to the group.
##  $2: The group to which the user should be added.
##
##  Return Codes:
##        0: The user was added successfully.
##      121: Argument for user name is missing or empty.
##      122: Argument for group name is missing or empty.
##        n: The operation to add the user failed; returns `dseditgroup` status.
##
function add_user_to_group() # <user_name> <group_name>
{
    typeset user_name="${1}"  ; [[ -n "${user_name}"  ]] || return 121
    typeset group_name="${2}" ; [[ -n "${group_name}" ]] || return 122

    check_user_for_group_membership "${user_name}" "${group_name}" && return 0

    echo_debug "Adding '${user_name}' to group '${group_name}'..."
    /usr/sbin/dseditgroup -o edit -a "${user_name}" -t user "${group_name}" >/dev/null || return $?
}


####
##  Print the available disk space for a given mount point or device path.
##  By default, the returned value is expressed in megabytes.
##
##  --bytes: Express the returned available space in bytes instead of megabytes.
##
##  $1: The mount point or device path. If no argument is provided,
##      '${JAMF_GLOBAL_TARGET_DRIVE_MOUNT_POINT}' will be read.  If that is also
##      unset, the root path '/' will be used.
##
function free_in_volume() # [--bytes] <volume_path>
{
    typeset -i use_bytes=0
    [[ "${1}" == "--bytes" ]] && { use_bytes=1 ; shift ; }

    typeset volume_path="${1}"
    [[ -n "${volume_path}" ]] || volume_path="${JAMF_GLOBAL_TARGET_DRIVE_MOUNT_POINT}"
    [[ -n "${volume_path}" ]] || volume_path="/"

    typeset volume_info ; volume_info="$( /usr/sbin/diskutil info -plist "${volume_path}" )" ||
    {
        diskutil_status=$? ; echo_log "Unable to get free disk space for '${volume_path}'." ERROR
        return $diskutil_status
    }

    typeset free_bytes_keypath=':APFSContainerFree'
    typeset free_bytes && free_bytes="$( /usr/libexec/PlistBuddy -c "Print ${free_bytes_keypath}" /dev/stdin <<< "${volume_info}" )" ||
    {
        typeset plistbuddy_status=$?
        echo_log "Unable to parse disk info for '${volume_path}'." ERROR
        return $plistbuddy_status
    }

    (( use_bytes )) &&
    {
        echo "${free_bytes}"
        return 0
    }

    # Limit MB format output to three decimal places.
    typeset -F3 free_mbytes
    free_mbytes=$(( ${free_bytes} / (1024.0 ** 2) ))

    echo "${free_mbytes}"
}


####
##  Remove a file or directory, with a test for existence and debug log message.
##
##  $1: The path to the file or directory to be removed.
##
function remove_existing() # <path_to_remove>
{
    [[ -f "${1}" ]] && { echo_debug "Removing file '${1}'..."      ; /bin/rm  -f "${1}" ; return $? }
    [[ -d "${1}" ]] && { echo_debug "Removing directory '${1}'..." ; /bin/rm -rf "${1}" ; return $? }

    echo_debug "No file or directory exists at '${1}'... skipped."
}


####
##  Print either the most recently logged-in user, or the user who logs in most
##  commonly, with options to filter out undesired users.
##
##  OPERATING MODES:
##      'recent' : Print the name of the most recently logged-in user, filtered
##          by the options below.
##      'commmon' : Print the name of the user who logs in most commonly,
##          filtered by the options below.
##
##  FILTERING OPTIONS:
##      -o --online-only : Consider only users who are currently logged in.
##      -t --include-tty : Include logins that are not bound to a console session;
##          i.e., non-GUI logins, such as terminal or SSH sessions.
##
function user_most() # (recent | common) [-o | --online_only] [-t | --include-tty]
{
    # Parse the options given to the function.
    zmodload zsh/zutil || return 10
    zparseopts -D -E -F -- \
        {h,-help}=help \
        {o,-online-only}=online_only \
        {t,-include-tty}=include_tty \
    || return 1

    # Configure the list of valid operating modes for this function.
    typeset -A modes=(
        mode_recent 'recent'
        mode_common 'common'
    )

    # Read the selected operating mode.  If the mode is not set or is not valid,
    # set the 'help' flag so that the usage text will be displayed.
    typeset mode="${1}"
    [[ "$mode" =~ "^(${(j'|')modes})\$" ]] || { help=( '--help' ) }

    # If the 'help' flag is set, display this function's usage text.
    if (( $#help )); then
        print -rC1 -- \
            "$0 [-h | --help]" \
            "$0 (${(j' | ')modes}) [-t | --include-tty] [-o | --online-only]"
        return
    fi

    # Configure 'awk' filter patterns to be ANDed together later.
    typeset -A filters=(
        is_not_blank  '(! /^$/)'
        is_not_status '(! /wtmp begins/)'
        is_console    '($2 == "console")'
        is_online     '/still logged in/'
    )

    # Configure 'awk' actions which will be combined later.
    typeset -A actions=(
        print_first_field  'print $1'
        print_second_field 'print $2'
        stop_reading       'exit 0'
    )

    # Create arrays to hold the patterns and actions for this function run.
    # Populate with values required regardless of mode.
    typeset -a filter_patterns=( "${filters[is_not_blank]}" "${filters[is_not_status]}" )
    typeset -a filter_actions=( "${actions[print_first_field]}" )

    # If we're in 'recent' mode, we'll stop reading after the filtering action.
    [[ "${mode}" == "${modes[mode_recent]}" ]] && { filter_actions+=( "${actions[stop_reading]}" ) }

    # Add each filter to the list of patterns, unless disabled by flags.
    (( $#include_tty )) || { filter_patterns+=( "${filters[is_console]}" ) }
    (( $#online_only )) && { filter_patterns+=( "${filters[is_online]}" ) }

    # Construct the 'awk' script, using the (j) zsh parameter expansion flag to
    # join the patterns and actions determined above.
    awk_script="${(j' && ')filter_patterns} { ${(j'; ')filter_actions} }"

    # Run the 'awk' command, using the constructed script.
    awk_output=$( /usr/bin/last | awk "${awk_script}" )

    # If we're in 'recent' mode, we're done here... echo the output and exit.
    [[ "${mode}" == "${modes[mode_recent]}" ]] &&
    {
        echo "${awk_output}"
        return 0
    }

    # Otherwise, since we're in 'common' mode, pipe the output through a few
    # commands to determine the most frequent user.
    echo "${awk_output}" \
        | sort \
        | uniq -c \
        | sort -rn \
        | awk "{ ${actions[print_second_field]}; ${actions[stop_reading]} }"
}


####
##  Print a "unique" path for a given file path; useful when you wish to avoid
##  overwriting an existing file.
##
##  Determines whether or not a file or directory exists at the given path.
##
##  If no file/folder exists, it will return the path unmodified.
##  If it does exist, it will attempt to generate a unique path by appending an
##  integer to the end, beginning at 1 and incrementing until the path is unique.
##
##  $1 : <path> Required.  Path to test for uniqueness
##
function unique_path() # <path>
{
    typeset original_path=${~"${1}"} ; [[ -n "${original_path}" ]] || fail 'Missing input path argument.' 10
    typeset unique_path="${original_path}"
    typeset -i index=0

    while [[ -e $unique_path ]] ; do
        (( index++ ))
        unique_path="${original_path:r}-$index.${original_path:e}"
    done

    echo "${unique_path}"
}


####
##  Replace the contents of target_file with those of source_file, preserving
##  the metadata and modification date of the target_file.
##
function mv_replace() # <source_file> <target_file>
{
    typeset source_file=${~"${1}"} ; [[ -n "${source_file}" && -f "${source_file}" ]] || fail 'Argument for source file is missing or empty, or file does not exist.' 10
    typeset target_file=${~"${2}"} ; [[ -n "${target_file}" && -f "${target_file}" ]] || fail 'Argument for target file is missing or empty, or file does not exist.' 11

    typeset target_date_modified="$(stat -f "%Sm" -t "%C%y%m%d%H%M.%S" "${target_file}")"

    mv    -f       "${source_file}"          "${target_file}" || fail     'Could not replace target file contents with source.' $?
    touch -c -m -t "${target_date_modified}" "${target_file}" || echo_log 'Could not reset target file modification date to pre-operation date.' WARNING
}


####
##  Options:
##      --validate-only : Dry run.  Print matching files without modification.
##
##  Arguments:
##      <description_pattern> : Each file specified by <input_files> will be
##          scanned by the 'file --brief' command.  If that command's output
##          does not matches this pattern, the file will its extension will be checked against the provided
##          list of <"valid extensions">.
##
##      <replacement_extension> : The extension which should be appended to
##          files which, according to the above criteria, do not have a valid
##          extension.
##
##      <input_file ...> : The path to the file to be evaluated.  Multiple paths
##          and glob patterns can be provided to evaluate multiple files.
##
##  Example Task:
##      Add a 'jpg' extension to files (not directories) which:
##          * are identified by the 'file' command as "JPEG" data, AND
##          * do not already have one of the following extensions:
##              * "jpeg", "jpg", "jpe", or "jfif" (case insensitive)
##  Example Command for Above Task:
##      fix_extension 'JPEG*' 'jpg' ^*.*(.)
##
function fix_extension() # [--validate-only] <description_pattern> <replacement_extension> <input_file ...>
{
    typeset -i validate_only=0

    [[ "${1}" = '--validate-only' ]] &&
    {
        echo_log "Validating only... no modifications will be made." INFO
        validate_only=1
        shift
    }

    [[ -n "${1}" ]] || fail "Argument for 'file --brief' match pattern is missing or empty" 10
    typeset file_command_pattern="${1}"

    shift ; [[ -n "${1}" ]] || fail "Argument for replacement extension is missing or empty" 30
    typeset replacement_extension="${1}"

    shift ; (( ${#@} )) || fail "Input file(s) missing or empty" 40
    typeset -a input_files=( ${@} )

    for input_file ( ${input_files} )
    {
        input_file=${~"${input_file}"}

        # If the output of `file` doesn't match what we're looking for, skip to the next file.
        [[ "$(file --brief -- ${input_file})" != ${~file_command_pattern} ]] && continue

        # Use the `file` command to determine the valid extensions for the file.
        typeset -a valid_extensions=( ${(s:/:)$(file --brief --extension ${input_file})} )

        # If the file's extension matches one of the specified extensions, skip to the next file.
        { [[ -n "${input_file:e}" ]] && (( $valid_extensions[(I)(#i)${input_file:e}] )) } && continue

        echo_log "Input file '${input_file}' extension should be one of: '${(j', ')valid_extensions}'.\c" INFO
        (( validate_only )) && { echo 1>&2 ; continue }

        echo ".. changing extension to '${replacement_extension}'." 1>&2
        mv -- ${input_file} "${input_file}.${replacement_extension}"
    }
}


####
##  Remove macOS-specific Finder metadata files, stored as files prefixed with '._'
##
function remove_finder_metadata_files() # [--recursive] [--dry-run]
{
    typeset working_path='.'
    typeset -a remove_cmd=(rm -v -f)
    typeset -a file_brief_cmd=(file --brief)
    typeset file_brief_description="AppleDouble encoded Macintosh file"

    [[ "${1}" = '--recursive' ]] && { working_path='**' ; shift ; }
    [[ "${1}" = '--dry-run'    ]] && { remove_cmd='echo' ; }

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


####
##  Print a recursive tree of files and folders from the given path.
##
function file_tree() # <start_path>
{
    typeset start_path=${~"${1}"}
    [[ -n "${start_path}" && -e "${start_path}" ]] || fail 'Argument for starting path is missing or empty, or nothing exists at the specified path.' 10

    find "${start_path}" | sed -e 's/[^-][^\/]*\// |/g' -e 's/|\([^ ]\)/|-\1/'
}


####
##  Prompt the user for a password using a secure (non-echoed) input, and echo
##  the entered text back to stdout.
##
##  This should be used in a context which will capture the output so that
##  sensitive information is not displayed on screen.
##
##  Example: Adding a password item to the Keychain:
##      % security add-internet-password -A -a 'username' \
##        -s 'secure.website.domain.net' -r 'htps' \
##        -w "$(ask_for_password)" 'login'
##
##  Example: Providing a password to the `curl` command:
##      % curl --user v076726:$(ask_for_password) ...
##
function ask_for_password()
{
    typeset password_input
    read -s 'password_input?Password:'
    echo $password_input
}


# #
# #  Download a large file, broken into chunks of a specified size
# #  (in megabytes, default is 20).
# #
# function download_chunked() # <remote_url> <output_file_path> <chunk_size=20>
# {
#     typeset dl_command remote_url output_file_path chunk_input
#     typeset -i chunk_size

#     dl_command="curl"

#     remote_url="${1}" ; [[ -n "${remote_url}" ]] || fail 'Argument for remote URL is missing or empty.' 10
#     output_file_path="${2}" ; [[ -n "${output_file_path}" ]] || fail 'Argument for output path is missing or empty.' 20
#     # Check output path's last directory exists, or fail
#     # Check output path's last directory is writable, or fail
#     chunk_input="${3}" ; [[ "${chunk_size}" == <-> ]] || { chunk_input='' ; echo "Specified chunk size is not valid.' INFO }
#     (( chunk_size = $chunk_input )) ; [[ "${chunk_size}" == <-> && -n "${chunk_size}" ]] || echo 'Using default chunk size of 20 MB.' INFO
#     # Check that chunk size is a non-zero integer, or log that the default will be used


# }
