##
##  ZSHRC EXTENSION:
##  Functions: Python
##


################################################################################
##  FUNCTIONS: Python


##
##  Update pip packages which are not requirements of another package; that is,
##  the packages which were directly installed by the user (a.k.a leaves).
##
function pip_upgrade_leaves()
{
    pip install --upgrade ${(f)"$(pip list --not-required --outdated --format 'json' | jq --raw-output '.[].name')"}
}
