################################################################################
#  FUNCTIONS: HOMEBREW

#
#  Generate .png of dependency tree for installed packages
#
#  Required Packages:
#      brew install martido/brew-graph/brew-graph
#      brew install graphviz
#
function brew-dependency-graph #
{
    brew-graph --installed --highlight-leaves | dot -Tpng -oBrewDependencies.png
}


#
#  Get options for installed package
#
#  Required Packages:
#      brew install jq
#
#  $1: Installed package name.
#
function brew-installed-options # <package>
{
    [[ $# -ge 1 ]]  || bail 'Missing package name argument.' 10

    local installation_info=$(brew info --json=v1 $1)

    echo ${installation_info} | jq --raw-output ".[].installed[0].used_options | @sh"
}


#
#  brew-reinstall-and-add-option <package> <options>
#  [WIP] Reinstall package with additional option(s)
#  - Parameters
#      - package: Installed package name
#      - options: The options to add when re-installing.
#  - Example
#      % brew-reinstall-and-add-option ffmpeg --with-libbluray --with-srt
#
#  # TODO: We're in zsh now... do this as a function.
#  alias brew-reinstall-and-add-option 'brew reinstall \!:1 `brew-installed-options \!:1` \!:2*'
#  set current_options = "`brew-installed-options ffmpeg`" && brew uninstall ffmpeg && brew install ffmpeg ${current_options} '--with-libvpx'
#
