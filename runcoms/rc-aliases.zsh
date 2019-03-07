#
# Defines all user-created aliases for shell commands
#


##
#  Process list, sorted by start time, ascending.
#
alias pst='ps -axwwo "lstart,pid,user,command" | sort -k5n -k2M -k3n -k4n -k6n'


##
#  Nighthawk
#  (Wow, remember NightHawk?  Never forget.)
#
#alias rmnhdb='cd ~/Library/Application\ Support/NightHawk/ ; rm -rf Database/ ; cd -'


##
#  Default Command Option Modifiers
#
#  ffmpeg: Hide banners
alias ffmpeg='ffmpeg -hide_banner'
alias ffprobe='ffprobe -hide_banner'
#
