##
##  ZSHRC EXTENSION:
##  Functions: Xcode
##


################################################################################
##  CONFIGURATION PARAMETERS

typeset -agx Z_RC_XCODE_PROCESS_SEARCH_ITEMS=( 'Xcode' 'CoreSimulator.framework' )



################################################################################
##  ALIASES
##

##  jq: Indent 4 spaces by default
alias jq='jq --indent 4'

##
##  Nighthawk
##  (Wow, remember NightHawk?  Never forget.)
##
#alias rmnhdb='cd ${HOME}/Library/Application\ Support/NightHawk/ ; rm -rf Database/ ; cd -'



################################################################################
##  FUNCTIONS: Xcode / Developer Tools
##

##
##  Trigger `softwareupdate` to download and install the Command-Line Tools for
##  the currently installed versions of Xcode and macOS.
##
function install_command_line_tools ()
{
    # trigger_file_path: The presence of an empty file with this specific name
    # and location causes the `softwareupdate` tool to include Command Line Tool
    # packages in its list of packages available for installation.
    typeset trigger_file_path="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"

    touch "${trigger_file_path}" || return 1

    echo_log --level 'INFO' "Installing / Updating Command-Line Tools..."

    typeset package_name && package_name="$( softwareupdate --verbose --list \
        | grep "\*.*Command Line" \
        | sort \
        | tail -n 1 \
        | sed -E 's/^ *\*( Label:)? *//' \
        | tr -d '\n' )" || return 1

    typeset swu_status
    softwareupdate --verbose --install "${package_name}"
    swu_status=$?

    rm -f "${trigger_file_path}"
    return $swu_status
}


##
##  Use 'pgrep' to list process within the Xcode bundle (i.e., processes with
##  'Xcode' in their path or process name), and processes within the
##  CoreSimulator framework bundle (i.e., processes with 'CoreSimulator' in
##  their path or process name)
##
function xcgrep ()
{
    for pvictim ( ${Z_RC_XCODE_PROCESS_SEARCH_ITEMS[*]} )
    {
        echo
        echo_log --level 'INFO' "Showing processes matching '${pvictim}'..."
        pgrep -fl "${pvictim}"
    }
    echo
}


##
##  Use 'pgrep' to kill process within the Xcode bundle (i.e., processes with
##  'Xcode' in their path or process name), and processes within the
##  CoreSimulator framework bundle (i.e., processes with 'CoreSimulator' in
##  their path or process name).
##
function xckill () # [-signal]
{
    for pvictim ( ${Z_RC_XCODE_PROCESS_SEARCH_ITEMS[*]} )
    {
        echo
        echo_log --level 'INFO' "Killing processes matching '${pvictim}'..."
        pkill ${1} -fl "${pvictim}"
    }
    echo
}


##
##
##
function log_create_predicate ()
{
    ## Create usage output.
    typeset -a usage=(
        "$0 [--help | -h ]"
        "$0 [--multi-field-search <filter_text>] [[--hide-subsystems <subsystem>]]"
        '    [--case-insensitive] [custom_predicate]'
    )

    ## Define parameter defaults.
    # typeset -a flag_help=( )
    # typeset -a arg_multi_field_search=( )
    # typeset -a arg_hide_subsystems=( )
    # typeset -a flag_case_insensitive=( '--case-insensitive' 0 )

    ## Configure parser and process function arguments.
    typeset -a parse_config=(
    #   '-a' 'options' # Specifies a default array to contain recognized options.
    #   '-A' 'options' # Same as -a, but using an associative array. Test: (( ${+options[--foo]} ))
        '-D'           # Remove found options from the positional parameters array ($@).
    #   '-E'           # Don't stop at the first string that isn't described by the specs.
        '-F'           # Stop and exit if a param is found which is not in the specs.
    #   '-K'           # Don't replace existing arrays (allows default values).
        '-M'           # Allows the 'name' in '=name' to reference another spec.
        '--'           # Indicates that options end here and spec starts.
        '-help=flag_help' 'h=-help' '?=-help'
        '-multi-field-search:=arg_multi_field_search'
        '-hide-subsystems+:=arg_hide_subsystems'
        '-case-insensitive=flag_case_insensitive'
    )

    ## Load parser and process function arguments.
    zmodload 'zsh/zutil'       || { echo_log --level 'ERROR' "Failed to load 'zsh/zutil' with status $?" ; return $? ; }
    zparseopts ${parse_config} || flag_help+='PARSE_FAIL'

    ## Display usage if help flag is set.
    (( ${#flag_help} )) && { echo_err "${(j:\n:)usage}" && return 0; }

    typeset modifier=""
    (( $#flag_case_insensitive )) && modifier='[cd]'

    typeset -a predicates=()

    (( ${#arg_multi_field_search} )) &&
    {
        typeset search_text=${arg_multi_field_search[2]}
        typeset -a contains_fields=(
            'category'
            'composedMessage'
            'process'
            'processImagePath'
            'sender'
            'senderImagePath'
            'subsystem'
        )
        typeset -a is_equal_fields=(
            'processIdentifier'
        )
        typeset -a search_subpredicates=()

        for field ( ${contains_fields} ) search_subpredicates+="(${field} CONTAINS${modifier} \"${search_text}\")"
        for field ( ${is_equal_fields} ) search_subpredicates+="(${field} == \"${search_text}\")"

        predicates+="${(j' OR ')search_subpredicates}"
    }

    (( ${#arg_hide_subsystems} )) &&
    {
        typeset -a hidden_subsystems=( )
        typeset -i keep=1
        for item ( ${arg_hide_subsystems} ) { (( keep ^= 1 )) && hidden_subsystems+="${item}" ; }  # One-liner to gather every other item from one array into another.

        typeset -a subsystem_subpredicates=( )
        for subsystem ( ${hidden_subsystems} ) subsystem_subpredicates+="(subsystem != \"${subsystem}\")"
        predicates+="${(j' AND ')subsystem_subpredicates}"
    }

    typeset extra_predicate="${1}"
    [[ -n "${extra_predicate}" ]] && predicates+="${extra_predicate}"

    echo "( ${(j' ) AND ( ')predicates} )"
}


##
##  Wrapper around `sudo log` which generates a predicate to search all fields
##  for a given string.
##
function log_filter ()  # [--level default | info | debug] [--style default | compact | json | syslog] [--hide-subsystem <subsystem[,...]>]' [--predicate <extra_predicate>] [--case-insensitive] <filter_text>
{
    ## Create usage output.
    typeset usage=(
        "$0 [--help]"
        "$0 [--case-insensitive] [--level default | info | debug] [--style default | compact | json | syslog]"
        '    [--hide-subsystem <subsystem[,...]>] [--predicate <extra_predicate>] <filter_text>'
    )

    ## Define parameter defaults.
    typeset -a flag_help=( )
    typeset -a flag_case_insensitive=( )
    typeset -a arg_level=( default )
    typeset -a arg_style=( compact )
    typeset -a arg_hide_subsystem=( )
    typeset -a arg_predicate=( )

    ## Parse function arguments.
    zmodload zsh/zutil || return 1
    zparseopts -D -F -K -- \
        -help=flag_help \
        -case-insensitive=flag_case_insensitive \
        -level:=arg_level \
        -style:=arg_style \
        -hide-subsystem:=arg_hide_subsystem \
        -predicate:=arg_predicate \
    || return 1

    ## Display usage if:
    ## * help flag is set
    ## * wrong number of positional args
    ## * positional arg value is empty string
    (( $#flag_help || ( $# != 1 ) || ( $#1 == 0 ) )) && { print -l $usage && return 0; }

    typeset filter="${1}"
    typeset modifier=""
    (( $#flag_case_insensitive )) && modifier='[cd]'

    typeset -a subpredicates=(
        "(category          CONTAINS${modifier} \"${filter}\")"
        "(composedMessage   CONTAINS${modifier} \"${filter}\")"
        "(process           CONTAINS${modifier} \"${filter}\")"
        "(processIdentifier ==                  \"${filter}\")"
        "(processImagePath  CONTAINS${modifier} \"${filter}\")"
        "(sender            CONTAINS${modifier} \"${filter}\")"
        "(senderImagePath   CONTAINS${modifier} \"${filter}\")"
        "(subsystem         CONTAINS${modifier} \"${filter}\")"
    )

    typeset predicate="${(j' OR ')subpredicates}"

    typeset -a hidden_subsystems=( ${(s:,:)arg_hide_subsystem[-1]} )
    (( $#hidden_subsystems )) &&
    {
        typeset -a subsystem_subpredicates=( )
        for subsystem ( ${hidden_subsystems} ) { subsystem_subpredicates+="(subsystem != \"${subsystem}\")" }
        predicate="(${(j' AND ')subsystem_subpredicates}) AND (${predicate})"
    }

    typeset extra_predicate="${arg_predicate[-1]}"
    [[ -n "${extra_predicate}" ]] &&
    {
        predicate="((${predicate}) AND (${extra_predicate}))"
    }

    sudo log stream --level "${arg_level[-1]}" --style "${arg_style[-1]}" --source --predicate "${predicate}"
}


##
##  Open VSCodium.  Avoids need to install `codium` executable.
##
function code ()  # [vscode_arg ...] [project_path]
{
    typeset -a helper_paths=(
        '/Applications/VSCodium.app/Contents/Resources/app/bin/codium'
        '/Applications/Visual Studio Code.app/Contents/Resources/app/bin/code'
    )

    for code_helper ( ${helper_paths} )
    {
        [[ -x "${code_helper}" ]] || code_helper="${HOME}${code_helper}"
        [[ -x "${code_helper}" ]] || continue
    }

    [[ -x "${code_helper}" ]] || { echo_log --level 'ERROR' 'VSCode does not appear to be installed.' ; return 1 ; }

    "${code_helper}" ${@}
}


##
##  Use `gitignore.io` to create a template .gitignore file for a swift project.
##  NOTE: Needs updating... doesn't seem to pull what I want anymore
##
function create_swift_gitignore ()
{
    curl -SLw "\n" "https://www.gitignore.io/api/swift,linux,xcode,macos,swiftpm,swiftpackagemanager" > .gitignore
}


##
##  Start `cafeinate` and keep it running, even if an irresponsible background
##  process kills it.
##
function overcaffeinate ()
{
    until {
        zmodload 'zsh/system'
        display_notification "Started by shell process ${sysparams[pid]}." '☕️ Caffeinated!'
        caffeinate -disu
    } {
        display_notification "Caffeinate was killed with status $?.  Restarting..." '😴 Decaffeinated'
        sleep 1
    } &!
}


##
##  List running processes, sorted by start time, ascending.
##
function ps_sorted_by_start_time
{
    ps -axwwo "lstart,pid,user,command" | sort -k5n -k2M -k3n -k4n -k6n
}

