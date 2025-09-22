##
##  ZPROFILE EXTENSION:
##  Homebrew Package Manager (brew)
##  https://brew.sh
##



################################################################################
##  SET HOMEBREW PREFIX
##  Use processor architecture to determine correct path.
##

typeset homebrew_prefix

case "$( uname -m )"
{
    x86_64) homebrew_prefix="/usr/local"    ;;
    arm64)  homebrew_prefix="/opt/homebrew" ;;
    *)      homebrew_prefix="/opt/homebrew" ;;
}

[[ -d "${homebrew_prefix}" ]] || return 0

typeset -gx HOMEBREW_PREFIX="${homebrew_prefix}"


####
##  AMEND `path` AND `fpath` WITH HOMEBREW PATHS.
##

path=(
    "${HOMEBREW_PREFIX}/"{bin,sbin}
    ${path}
)

fpath=(
    "${HOMEBREW_PREFIX}/share/zsh/site-functions"
    ${fpath}
)


