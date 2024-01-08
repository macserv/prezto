##
##  ZPROFILE EXTENSION:
##  Homebrew Package Manager (brew)
##  https://brew.sh
##


typeset -gx HOMEBREW_PREFIX
case "$( uname -m )" in
    x86_64) HOMEBREW_PREFIX="/usr/local"    ;;
    arm64)  HOMEBREW_PREFIX="/opt/homebrew" ;;
    *)      HOMEBREW_PREFIX="/opt/homebrew" ;;
esac

path=(
    ${HOMEBREW_PREFIX}/{bin,sbin}
    ${path}
)

fpath=(
    ${HOMEBREW_PREFIX}/share/zsh/site-functions
    ${fpath}
)
