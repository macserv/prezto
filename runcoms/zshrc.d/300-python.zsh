##
##  ZSHRC EXTENSION:
##  Functions: Python
##


################################################################################
##  FUNCTIONS: Python


##
##  Print a list of pip packages which are not required by other packages
##  i.e., the "leaves" of the dependency tree.  Named after `brew leaves`.
##
##  ARGUMENTS
##  ---------
##  All arguments to this command will be passed to `pip`.
##
function pip_leaves ()  # [pip_argument ...]
{
    pip list --not-required ${@}
}


##
##  Update pip packages which are not requirements of another package; that is,
##  the packages which were directly installed by the user (a.k.a leaves).
##
function pip_upgrade_leaves ()
{
    pip install --upgrade ${(f)"$(pip_leaves --outdated --format 'json' | jq --raw-output '.[].name')"}
}


##
##  WIP
##
function pip_uninstall_recursive ()  # <package> [parent] [indent]
{
    typeset package="${1}"
    typeset parent="${2}"
    typeset -i indent="${3}"
    typeset pip_list_before && pip_list_before=$( pip_leaves --format 'freeze' )

    typeset dependency_output=", on which '${parent}' depended"
    echo_log --level 'INFO' --indent ${indent:-0} "Removing package '${package}'${parent:+${dependency_output}}..."
    pip uninstall --yes --quiet "${package}"

    # Generate a `diff` of the "leaf" package list, before and after removing the package.
    typeset pip_leaves_after && pip_leaves_after=$( pip_leaves --format 'freeze' )
    typeset pip_leaves_diff  && pip_leaves_diff=$( diff <( echo "${pip_list_before}" ) <( echo "${pip_leaves_after}" ) )
    typeset add_prefix='> '

    # Turn the diff into a list of dependency packages which have now become leaves.
    typeset -a pip_list_new_leaves=( ${${(M)${(f)pip_leaves_diff}:#${add_prefix}*}#${add_prefix}} )
    #                                          ^ Split into array on newlines.
    #                                     ^ Invert filtering.    ^ Filter out items *NOT* starting with '> '.
    #                                                                             ^ Strip '> ' prefix from all items.
    for new_leaf ( ${pip_list_new_leaves} )
    {
        pip_uninstall_recursive "${new_leaf}" "${parent}" $(( indent + 1 ))
    }
}

