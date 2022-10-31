#
# ZSHRC EXTENSION:
# Functions: Homebrew
#


#
#  Generate .png of dependency tree for installed packages
#
#  Required Packages:
#      brew install martido/brew-graph/brew-graph
#      brew install graphviz
#
function brew_dependency_graph() # [package ...]
{
    local dependency_name="${(j'-')@}"
    [[ -z "$dependency_name" ]] && dependency_name="all"
    brew graph --installed --highlight-leaves --highlight-outdated $@ | dot -Tpdf -obrew-dependencies-${dependency_name}.pdf
}


#
#  Get options for installed package
#
#  Required Packages:
#      brew install jq
#
#  $1: Installed package name.
#
function brew_installed_options() # <package>
{
    [[ $# -ge 1 ]]  || fail 'Missing package name argument.' 10

    typeset installation_info=$(brew info --json=v1 $1)

    jq --raw-output ".[].installed[0].used_options | @sh" <<< "${installation_info}"
}


#
#  brew_reinstall_and_add_option <package> <options>
#  [WIP] Reinstall package with additional option(s)
#  - Parameters
#      - package: Installed package name
#      - options: The options to add when re-installing.
#  - Example
#      % brew_reinstall_and_add_option ffmpeg --with-libbluray --with-srt
#
#  # TODO: We're in zsh now... do this as a function.
#  alias brew_reinstall_and_add_option 'brew reinstall \!:1 `brew_installed_options \!:1` \!:2*'
#  set current_options = "`brew_installed_options ffmpeg`" && brew uninstall ffmpeg && brew install ffmpeg ${current_options} '--with-libvpx'
#


#
#  List all brew leaves with their description appended.
#
function brew_leaves_with_info()
{
    for formula ( $(brew leaves) )
    {
        typeset description=$(brew info --json --formula "${formula}" | jq --raw-output '.[0].desc')
        echo "${formula} : ${description}"
    }
}
