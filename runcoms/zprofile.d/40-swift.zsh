##
##  ZPROFILE EXTENSION:
##  swift
##



################################################################################
##  MINT SUPPORT
##  https://github.com/yonaskolb/Mint
##

typeset mint_path="${HOME}/.mint"
[[ -x "${mint_path}/bin/mint" ]] || return 0


typeset -gx MINTPATH="${mint_path}"


####
##  AMEND `path` WITH PATH TO Mint EXECUTABLE.
##

path=(
    "${MINTPATH}/bin"
    ${path}
)

