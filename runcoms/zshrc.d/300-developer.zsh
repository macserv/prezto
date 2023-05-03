##
##  ZSHRC EXTENSION:
##  Functions: Xcode
##


################################################################################
##  CONFIGURATION: GLOBAL PARAMETERS

typeset -agx Z_RC_XCODE_PROCESS_SEARCH_ITEMS=( 'Xcode' 'CoreSimulator.framework' )



################################################################################
##  FUNCTIONS: Xcode / Developer Tools


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

    echo_log "Installing / Updating Command-Line Tools..." INFO

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
        echo_log "Showing processes matching '${pvictim}'..." INFO
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
function xckill ()  # [-signal]
{
    for pvictim ( ${Z_RC_XCODE_PROCESS_SEARCH_ITEMS[*]} )
    {
        echo
        echo_log "Killing processes matching '${pvictim}'..." INFO
        pkill ${1} -fl "${pvictim}"
    }
    echo
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
    zparseopts -D -F -K --                      \
        -help=flag_help                         \
        -case-insensitive=flag_case_insensitive \
        -level:=arg_level                       \
        -style:=arg_style                       \
        -hide-subsystem:=arg_hide_subsystem     \
        -predicate:=arg_predicate               \
    || return 1

    ## Display usage if:
    ## * help flag is set
    ## * wrong number of positional args
    ## * positional arg value is empty string
    (( $#flag_help || ( $# != 1 ) || ( $#1 == 0 ) )) && { print -l $usage && return ; }

    typeset filter="${1}"
    typeset modifier=""
    (( $#flag_case_insensitive )) && modifier='[cd]'

    typeset -a subpredicates=(
        "(category          CONTAINS${modifier} \"${filter}\")"
        "(composedMessage   CONTAINS${modifier} \"${filter}\")"
        "(process           CONTAINS${modifier} \"${filter}\")"
        "(processIdentifier ==                  \"${filter}\")"
    #   "(processImagePath  CONTAINS${modifier} \"${filter}\")"
        "(sender            CONTAINS${modifier} \"${filter}\")"
    #   "(senderImagePath   CONTAINS${modifier} \"${filter}\")"
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

    sudo log stream --level "${arg_level[-1]}" --style "${arg_style[-1]}" --predicate "${predicate}"
}


##
##  Open VSCodium.  Avoids need to install `codium` executable.
##
function code ()
{
    typeset code_helper_path='/Applications/VSCodium.app/Contents/Resources/app/bin/codium'
    [[ ! -f "${code_helper_path}" ]] && code_helper_path="${HOME}${code_helper_path}"
    "${code_helper_path}" $@
}


##
##  Use `gitignore.io` to create a template .gitignore file for a swift project.
##  NOTE: Needs updating... doesn't seem to pull what I want anymore
##
function create_swift_gitignore ()
{
    curl -SLw "\n" "https://www.gitignore.io/api/swift,linux,xcode,macos,swiftpm,swiftpackagemanager" > .gitignore
}

