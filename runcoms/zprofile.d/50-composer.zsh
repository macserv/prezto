##
##  ZPROFILE EXTENSION:
##  composer (PHP)
##


typeset composer_path="${HOME}/.composer/vendor/bin"
[[ -d "${composer_path}" ]] || return 0


path=(
    "${composer_path}"
    ${path}
)
