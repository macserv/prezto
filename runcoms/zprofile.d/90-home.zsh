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

path=(
    ${HOME}/{Local,.local}/{bin,sbin}
    ${path}
)

cdpath=(
    ${HOME}
    ${HOME}/Projects/Development
    ${cdpath}
)

fpath=(
    ${HOME}/{Local,.local}/share/zsh/site-functions
    ${fpath}
)
