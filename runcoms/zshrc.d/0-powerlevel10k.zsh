#
# PowerLevel10K Prompt Configuration
#

# ZSH Right Prompt Indentation
ZLE_RPROMPT_INDENT=0


###############################################################################
# P10K General Configuration
#

# P10K Mode
POWERLEVEL9K_MODE='awesome-fontconfig'

# P10K Prompt Segments
POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=('os_icon' 'dir' 'vcs' 'root_indicator' 'dir_writable')
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=('status' 'background_jobs' 'time' 'node_version' 'swift_version')

# P10K Segment Separators
POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0C6'  # ''
POWERLEVEL9K_LEFT_SEGMENT_END_SEPARATOR='  '
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0C7' # ''


###############################################################################
# P10K Segment-Specific Configuration
#

# P10K Segment Config: 'os_icon'
POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION="$(echo '\uE711') " # ''

# P10K Segment Config: 'dir'
POWERLEVEL9K_HOME_ICON=''
POWERLEVEL9K_HOME_SUB_ICON=''
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_HOME_FOLDER_ABBREVIATION='\uF015 ' # ''
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_SHORTEN_DELIMITER="\u2425" # '␥'

# P10K Segment Config: 'root_indicator'
POWERLEVEL9K_ROOT_ICON='\uF0E7 ' # ''
POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND='darkred'

# P10K Segment Config: 'dir_writable'
POWERLEVEL9K_LOCK_ICON='\uF8EE ' # ''

# P10K Segment Config: 'status'
POWERLEVEL9K_STATUS_OK='false'

# P10K Segment Config: 'time'
POWERLEVEL9K_TIME_FORMAT="%D{%d.%m.%y \uF073  \uE0B3 %H:%M}" # '' ''

# P10K Segment Config: 'node_version'
# POWERLEVEL9K_NODE_VERSION_PROJECT_ONLY='true' # Only show segment when in project using Node
POWERLEVEL9K_NODE_VERSION_FOREGROUND='silver' # Terminal color 15

# P10K Segment Config: 'swift_version'
POWERLEVEL9K_SWIFT_ICON='\uE755 ' # ''
POWERLEVEL9K_SWIFT_VERSION_BACKGROUND='darkorange3' # Terminal color 166
POWERLEVEL9K_SWIFT_VERSION_FOREGROUND='silver' # Terminal color 15
