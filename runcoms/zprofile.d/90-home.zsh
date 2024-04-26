##
##  ZPROFILE EXTENSION:
##  Home Directory
##


################################################################################
# Paths

path=(
    ${HOME}/{Local,.local}/{bin,sbin}
    $path
)

cdpath=(
    ${HOME}
    ${HOME}/Projects/Development
    $cdpath
)

fpath=(
    ${HOME}/{Local,.local}/share/zsh/site-functions
    ${fpath}
)

