##
##  ZPROFILE EXTENSION:
##  swift
##


typeset mint_path="${HOME}/.mint"
[[ -x "${mint_path}/bin/mint" ]] || return 0


typeset -gx MINTPATH="${mint_path}"

path=(
    "${MINTPATH}/bin"
    ${path}
)

