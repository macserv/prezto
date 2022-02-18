#
# ZSHRC EXTENSION:
# Functions: Xcode
#


################################################################################
#  CONFIGURATION: GLOBAL PARAMETERS

typeset -agx Z_RC_XCODE_PROCESS_SEARCH_ITEMS
Z_RC_XCODE_PROCESS_SEARCH_ITEMS=( 'Xcode' 'CoreSimulator.framework' )



################################################################################
#  FUNCTIONS: Xcode / Developer Tools


#
#  Trigger `softwareupdate` to download and install the Command-Line Tools for
#  the currently installed versions of Xcode and macOS.
#
function install_command_line_tools()
{
    typeset trigger_file_path package_name swu_status
    
    # trigger_file_path: The presence of an empty file with this specific name
    # and location causes the `softwareupdate` tool to include Command Line Tool
    # packages in its list of packages available for installation.
    trigger_file_path="/tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress"
    
    touch "${trigger_file_path}" || return 1
    
    echo_log "Installing / Updating Command-Line Tools..." INFO
    
    package_name="$( softwareupdate --verbose --list \
        | grep "\*.*Command Line" \
        | sort \
        | tail -n 1 \
        | sed -E 's/^ *\*( Label:)? *//' \
        | tr -d '\n' )" || return 1
    
    softwareupdate --verbose --install "${package_name}" ; swu_status=$?
    
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

