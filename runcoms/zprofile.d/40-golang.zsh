##
##  ZPROFILE EXTENSION:
##  golang
##


{ [[ -s "${local_goenv::=${GOENV_ROOT:-$HOME/.goenv}/bin/goenv}" ]] || (( ${+commands[goenv]} )) } &&
{
    [[ -s "${local_goenv}" ]] &&
    {
        # Amend ${path} with goenv binary path.
        path=( ${local_goenv:h} ${path} )

        # Load goenv into environment.
        eval "$( goenv init - 'zsh' )"

        # Override default paths.
        typeset -gx GOPATH="${HOME}/.local/share/go"
        typeset -gx GOCACHE="${HOME}/.cache/go/build"
        typeset -gx GOMODCACHE="${HOME}/.cache/go/mod"
        typeset -gx GOENV="${HOME}/.config/go/env"

        # Amend ${path} with golang binary paths.
        [[ -d "${GOROOT}/bin" ]] && path=( "${GOROOT}/bin" ${path} )
        [[ -d "${GOPATH}/bin" ]] && path=( ${path} "${GOPATH}/bin" )
    }
}

unset local_goenv

