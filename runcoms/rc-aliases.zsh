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
#  flake8: Default ignore options
alias flake8='flake8 --show-source --ignore=W,E501,E203,W293,E303,E221'
#  pylint: Default ignore options
alias pylint='pylint --disable=bad-whitespace,trailing-whitespace,line-too-long,trailing-newlines'
#
#  jq: Indent 4 spaces by default
alias jq='jq --indent 4'


##
#  Git convenience additions
#
#  Open difftool with directory diff
alias gD='git difftool --dir-diff'
alias git-current-branch='git rev-parse --abbrev-ref HEAD'
