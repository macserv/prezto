#
# ZSHRC EXTENSION:
# Prompt (powerlevel10k)
#


##  TODO: Make this work on Apple Silicon and re-enable.
# function prompt_my_cpu_temp ()
# {
#     typeset -i cpu_temp="$( sysctl 'machdep.xcpm.cpu_thermal_level' 2>& - | awk '{print $2}' )"

#     (( ! cpu_temp ))     && return
#     (( cpu_temp >= 89 )) && { p10k segment -s FIRE     -f maroon      -b grey30 -i $'\U0001F525 ' ; return ; }
#     (( cpu_temp >= 78 )) && { p10k segment -s SCALDING -f orangered1  -b grey30 -i $'\U0000F2C7 ' ; return ; }
#     (( cpu_temp >= 67 )) && { p10k segment -s HOT      -f orange3     -b grey30 -i $'\U0000F2C8 ' ; return ; }
#     (( cpu_temp >= 56 )) && { p10k segment -s WARM     -f olive       -b grey30 -i $'\U0000F2C9 ' ; return ; }
#     (( cpu_temp >= 45 )) && { p10k segment -s TEPID    -f green       -b grey30 -i $'\U0000F2CA ' ; return ; }
#                               p10k segment -s COOL     -f dodgerblue1 -b grey30 -i $'\U0000F2CB ' ; return
# }


function prompt_my_caffeinate ()
{
    pgrep 'caffeinate' &>/dev/null && { p10k segment -f grey15 -b silver -i $'\U0000E005 ' ; return ; }
}


# ZSH Right Prompt Indentation
ZLE_RPROMPT_INDENT=0

# History Fuzzy Search (any non-empty value enables)
HISTORY_SUBSTRING_SEARCH_FUZZY='true'


###############################################################################
# P10K General Configuration
#

# Configure high-level behaviors
typeset -g POWERLEVEL9K_MODE='nerdfont-complete'
typeset -g POWERLEVEL9K_ICON_PADDING='moderate'
typeset -g POWERLEVEL9K_TRANSIENT_PROMPT='always'
# typeset -g POWERLEVEL9K_PROMPT_ADD_NEWLINE='true'

# Configure horizontal rule above prompt
typeset -g POWERLEVEL9K_SHOW_RULER=true
typeset -g POWERLEVEL9K_RULER_CHAR='\U0001FB7B'  # '🭻'
typeset -g POWERLEVEL9K_RULER_FOREGROUND=236

# Use traditional symbols for user/root commands in the scrollback.
typeset -g POWERLEVEL9K_PROMPT_CHAR_{OK,ERROR}_VIINS_CONTENT_EXPANSION='%#'


###############################################################################
# P10K Segment Configuration
#

# Lay out segments in four groups: top/bottom line, left/right edge of terminal
t_l=( 'dir_writable' 'dir' 'vcs' );         t_r=( 'background_jobs' 'my_caffeinate' 'swift_version' 'time' )
b_l=( 'os_icon' 'root_indicator' );                                b_r=( 'command_execution_time' 'status' )

# Combine segment layout into p10k config parameters
typeset -g POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=( ${t_l} 'newline' ${b_l} )
typeset -g POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=( ${t_r} 'newline' ${b_r} )

# Use custom segment separators
typeset -g POWERLEVEL9K_LEFT_SEGMENT_END_SEPARATOR=' '        # Single space after prompt.
typeset -g POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\U0000E0C6 '  # '' (with added space for double width)
typeset -g POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\U0000E0C7 ' # '' (with added space for double width)


###############################################################################
# P10K Segment-Specific Configuration
#

# P10K Segment Config: 'os_icon'
typeset -g POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION="$(echo '\U0000E711') "  # ''
typeset -g POWERLEVEL9K_OS_ICON_BACKGROUND=237

# P10K Segment Config: 'dir'
typeset -g POWERLEVEL9K_DIR_HOME_ICON=''
typeset -g POWERLEVEL9K_DIR_HOME_SUB_ICON=''
typeset -g POWERLEVEL9K_DIR_FOLDER_ICON=''
typeset -g POWERLEVEL9K_HOME_FOLDER_ABBREVIATION='\U0000F015 ' # ''
typeset -g POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
typeset -g POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
typeset -g POWERLEVEL9K_SHORTEN_DELIMITER="\U00002425" # '␥'

# P10K Segment Config: 'root_indicator'
typeset -g POWERLEVEL9K_ROOT_INDICATOR_ROOT_ICON='\U0000F0E7 ' # ''
typeset -g POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND='darkred'

# P10K Segment Config: 'dir_writable'
typeset -g POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_LOCK_ICON='\U0000F8EE ' # ''
typeset -g POWERLEVEL9K_DIR_WRITABLE_FOREGROUND='yellow'
typeset -g POWERLEVEL9K_DIR_WRITABLE_BACKGROUND='darkred'

# P10K Segment Config: 'status'
typeset -g POWERLEVEL9K_STATUS_OK='false'

# P10K Segment Config: 'time'
typeset -g POWERLEVEL9K_TIME_FORMAT="%D{%d.%m.%y \U0000F073  \U0000E0B3 %H:%M}" # '' ''

# P10K Segment Config: 'swift_version'
typeset -g POWERLEVEL9K_SWIFT_ICON='\U0000E755 ' # ''
typeset -g POWERLEVEL9K_SWIFT_VERSION_BACKGROUND='darkorange3' # Terminal color 166
typeset -g POWERLEVEL9K_SWIFT_VERSION_FOREGROUND='silver' # Terminal color 15
