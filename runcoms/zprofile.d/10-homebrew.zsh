##
##  ZPROFILE EXTENSION:
##  HomeBrew (brew)
##


typeset -gx HOMEBREW_NO_INSTALL_FROM_API=1

typeset -gx HOMEBREW_PREFIX
HOMEBREW_PREFIX="/opt/homebrew"
[[ "$(uname -m)" == 'x86_64' ]] && { HOMEBREW_PREFIX="/usr/local" }

path=(
    ${HOMEBREW_PREFIX}/{bin,sbin}
    $path
)

fpath=(
    ${HOMEBREW_PREFIX}/share/zsh/site-functions  # Homebrew (Chase installation location)
    $fpath
)
