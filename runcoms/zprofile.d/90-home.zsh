##
##  ZPROFILE EXTENSION:
##  Home Directory
##


################################################################################
##  PATHS
##
##  Add user-specific inclusions to the user's path-related environment
##  variables.  Modify the lowercased array variants for cleanliness.  These
##  modifications will be automatically mirrored to the scalar (all-caps)
##  variants of the variables.

typeset -agU path=(
    ${HOME}/{Local,.local}/{bin,sbin}
    $path
)

typeset -agU cdpath=(
    ${HOME}
    ${HOME}/Projects/Development
    $cdpath
)

typeset -agU fpath=(
    ${HOME}/{Local,.local}/share/zsh/site-functions
    ${fpath}
)


##  Export the scalar (semicolon-separated, non-array) all-caps variants of the
##  user's path-related environment variables, since arrays can not be exported.
typeset -gx PATH
typeset -gx CDPATH
typeset -gx FPATH


