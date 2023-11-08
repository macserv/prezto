##
##  ZPROFILE EXTENSION:
##  golang
##


{ [[ -s "${local_goenv::=${GOENV_ROOT:-$HOME/.goenv}/bin/goenv}" ]] || (( ${+commands[goenv]} )) } &&
{
    [[ -s "${local_goenv}" ]] &&
    {
        # Add `goenv` bin folder to path.
        path=( ${local_goenv:h} ${path} )

        # Load goenv into environment.
        eval "$( goenv init - 'zsh' )"

        [[ -d "${GOROOT}/bin" ]] && path=( "${GOROOT}/bin" ${path} )
        [[ -d "${GOPATH}/bin" ]] && path=( ${path} "${GOPATH}/bin" )
    }
}

unset local_goenv

# [[ -n "${commands[go]}" ]] && { go env -w GOPATH=$HOME/.cache/go ; }

