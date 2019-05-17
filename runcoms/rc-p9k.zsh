#
#  
#
#
#


# ZLE_RPROMPT_INDENT=0   # Removes space after RPROMPT.  Causes cursor positioning issues.
# ZLE_RPROMPT_INDENT=-1  # Avoids cursor issue, but causes issues with Terminal.app line clearing.

P9K_LEFT_PROMPT_ELEMENTS=(os_icon dir vcs root_indicator)
P9K_RIGHT_PROMPT_ELEMENTS=(status background_jobs time swift_version)

P9K_MODE='awesome-fontconfig'

P9K_LEFT_SEGMENT_SEPARATOR_ICON='\uE0C6 '
P9K_RIGHT_SEGMENT_SEPARATOR_ICON='\uE0C7'
P9K_SWIFT_VERSION_ICON='\uE755 '
P9K_OS_ICON_ICON='\uE711 '

P9K_DIR_HOME_ICON=''
P9K_DIR_HOME_SUBFOLDER_ICON=''
P9K_DIR_DEFAULT_ICON=''
P9K_DIR_HOME_FOLDER_ABBREVIATION='\uF015 '
P9K_DIR_SHORTEN_STRATEGY="truncate_middle"
P9K_DIR_SHORTEN_LENGTH=3
P9K_DIR_SHORTEN_DELIMITER="\u2425"

P9K_TIME_FORMAT="%D{%d.%m.%y \uF073  \uE0B3 %H:%M}"
P9K_BATTERY_STAGES=($'\uF244 ' $'\uF243 ' $'\uF242 ' $'\uF241 ' $'\uF240 ')
P9K_BATTERY_VERBOSE=false
P9K_STATUS_OK=false

P9K_ROOT_INDICATOR_ICON='\u26A1'
P9K_ROOT_INDICATOR_BACKGROUND='darkred'
