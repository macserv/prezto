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
function pip_upgrade_leaves ()
{
    pip install --upgrade ${(f)"$(pip list --not-required --outdated --format 'json' | jq --raw-output '.[].name')"}
}


##
##
##
function pip_uninstall_recursive ()  # <package> [parent] [indent]
{
    typeset package="${1}"
    typeset parent="${2}"
    typeset -i indent="${3}"
    typeset pip_list_before && pip_list_before=$( pip list --not-required --format 'freeze' )

    typeset dependency_output=", on which '${parent}' depended"
    echo_log --level 'INFO' --indent ${indent:-0} "Removing package '${package}'${parent:+${dependency_output}}..."
    pip uninstall --yes --quiet "${package}"

    # Generate a `diff` of the "leaf" package list, before and after removing the package.
    typeset pip_list_after && pip_list_after=$( pip list --not-required --format 'freeze' )
    typeset pip_list_diff  && pip_list_diff=$( diff <( echo "${pip_list_before}" ) <( echo "${pip_list_after}" ) )
    typeset add_prefix='> '

    # Turn the diff into a list of dependency packages which have now become leaves.
    typeset -a pip_list_new_leaves=( ${${(M)${(f)pip_list_diff}:#${add_prefix}*}#${add_prefix}} )
    #                                          ^ Split into array on newlines.
    #                                     ^ Invert filtering.  ^ Remove items *NOT* starting with '> '.
    #                                                                           ^ Strip '> ' prefix from all items.
    for new_leaf ( ${pip_list_new_leaves} )
    {
        pip_uninstall_recursive "${new_leaf}" "${parent}" $(( indent + 1 ))
    }
}

