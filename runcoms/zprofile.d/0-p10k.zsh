#
#  
#
#
#


ZLE_RPROMPT_INDENT=0

POWERLEVEL9K_LEFT_PROMPT_ELEMENTS=('os_icon' 'dir' 'vcs' 'root_indicator' 'dir_writable')
POWERLEVEL9K_RIGHT_PROMPT_ELEMENTS=('status' 'background_jobs' 'time' 'swift_version')

POWERLEVEL9K_MODE='awesome-fontconfig'

POWERLEVEL9K_LEFT_SEGMENT_SEPARATOR='\uE0C6 '
POWERLEVEL9K_RIGHT_SEGMENT_SEPARATOR='\uE0C7'
POWERLEVEL9K_SWIFT_ICON='\uE755 '
POWERLEVEL9K_OS_ICON_CONTENT_EXPANSION="$(echo '\uE711') "

POWERLEVEL9K_HOME_ICON=''
POWERLEVEL9K_HOME_SUB_ICON=''
POWERLEVEL9K_FOLDER_ICON=''
POWERLEVEL9K_HOME_FOLDER_ABBREVIATION='\uF015 '
POWERLEVEL9K_SHORTEN_STRATEGY="truncate_middle"
POWERLEVEL9K_SHORTEN_DIR_LENGTH=3
POWERLEVEL9K_SHORTEN_DELIMITER="\u2425"

POWERLEVEL9K_TIME_FORMAT="%D{%d.%m.%y \uF073  \uE0B3 %H:%M}"
POWERLEVEL9K_STATUS_OK=false

POWERLEVEL9K_ROOT_ICON='\uF0E7 '
POWERLEVEL9K_ROOT_INDICATOR_BACKGROUND='darkred'

POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_FOREGROUND='yellow'
POWERLEVEL9K_DIR_WRITABLE_FORBIDDEN_BACKGROUND='darkred'
POWERLEVEL9K_LOCK_ICON='\uF8EE '
