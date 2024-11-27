##
##  ZPROFILE EXTENSION:
##  swift
##

typeset -gx MINTPATH="${HOME}/.mint"
[[ -x "${MINTPATH}/bin/mint" ]] || return 0

path=( "${MINTPATH}/bin" ${path} )

