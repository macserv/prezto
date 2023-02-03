#
# ZSHRC EXTENSION:
# Functions: Xcode
#


################################################################################
#  CONFIGURATION: GLOBAL PARAMETERS

typeset -agx Z_RC_XCODE_PROCESS_SEARCH_ITEMS=( 'Xcode' 'CoreSimulator.framework' )



################################################################################
#  FUNCTIONS: Xcode / Developer Tools


#
#  Trigger `softwareupdate` to download and install the Command-Line Tools for
#  the currently installed versions of Xcode and macOS.
#
function install_command_line_tools()
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


#
#  Use 'pgrep' to list process within the Xcode bundle (i.e., processes with
#  'Xcode' in their path or process name), and processes within the
#  CoreSimulator framework bundle (i.e., processes with 'CoreSimulator' in
#  their path or process name)
#
function xcgrep()
{
    for pvictim ( ${Z_RC_XCODE_PROCESS_SEARCH_ITEMS[*]} )
    {
        echo
        echo_log "Showing processes matching '${pvictim}'..." INFO
        pgrep -fl "${pvictim}"
    }
    echo
}


#
#  Use 'pgrep' to kill process within the Xcode bundle (i.e., processes with
#  'Xcode' in their path or process name), and processes within the
#  CoreSimulator framework bundle (i.e., processes with 'CoreSimulator' in
#  their path or process name).
#
function xckill() # [-signal]
{
    for pvictim ( ${Z_RC_XCODE_PROCESS_SEARCH_ITEMS[*]} )
    {
        echo
        echo_log "Killing processes matching '${pvictim}'..." INFO
        pkill ${1} -fl "${pvictim}"
    }
    echo
}


#
#  Wrapper around `sudo log` which generates a predicate to search all fields
#  for a given string.
#
function log-filter() # --case-insensitive <search_term>
{
    ## Create usage output.
    typeset usage=(
        "$0 [--help]"
        "$0 [--case-insensitive] [--level default | info | debug]"
        '    [--style default | compact | json | syslog] <filter_text>'
    )

    ## Define parameter defaults.
    typeset -a flag_help=( $( (( $# > 0 )) || echo "NO_ARGS" ) )
    typeset -a flag_case_insensitive=( )
    typeset -a arg_level=( default )
    typeset -a arg_style=( compact )
    
    ## Parse function arguments.
    zparseopts -D -F -K -- \
        -help=flag_help \
        -case-insensitive=flag_case_insensitive \
        -level:=arg_level \
        -style:=arg_style \
    || return 1

    ## Display usage if help flag is set.
    (( $#flag_help )) && { print -l $usage && return }

    typeset modifier=""
    (( $#flag_case_insensitive )) && modifier='[c]'

    typeset -a subpredicates=(
        "(category          CONTAINS${modifier} \"${1}\")"
        "(composedMessage   CONTAINS${modifier} \"${1}\")"
        "(process           CONTAINS${modifier} \"${1}\")"
        "(processIdentifier ==                  \"${1}\")"
    #   "(processImagePath  CONTAINS${modifier} \"${1}\")"
        "(sender            CONTAINS${modifier} \"${1}\")"
    #   "(senderImagePath   CONTAINS${modifier} \"${1}\")"
        "(subsystem         CONTAINS${modifier} \"${1}\")"
    )

    typeset predicate="${(j' OR ')subpredicates}"

    sudo log stream --level "${arg_level[-1]}" --style "${arg_style[-1]}" --predicate "${predicate}"
}


#
#  Open VSCodium.  Avoids need to install `codium` executable.
#
function code()
{
    /Applications/VSCodium.app/Contents/Resources/app/bin/codium
}


#
#  Use `gitignore.io` to create a template .gitignore file for a swift project.
#  NOTE: Needs updating... doesn't seem to pull what I want anymore
#
function create_swift_gitignore() #
{
    curl -SLw "\n" "https://www.gitignore.io/api/swift,linux,xcode,macos,swiftpm,swiftpackagemanager" > .gitignore
}

