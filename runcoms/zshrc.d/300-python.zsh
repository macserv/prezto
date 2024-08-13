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
##  Remove a list of pip packages, along with any packages that are no longer
##  required by any other installed packages.
##
function pip_uninstall_leaves ()  # [--indent <level>] <package ...>
{
    typeset -i indent=0
    [[ ${1} == '--indent' ]] && { indent=${2} ; shift 2 }

    typeset pip_leaves_before
    typeset pip_leaves_after
    typeset pip_leaves_diff

    for package ( ${@} )
    {
        echo_log --level 'INFO' --indent ${indent} "Removing package '${package}'..."

        # Generate a `diff` of the "leaf" package list, before and after removing the package.
        pip_leaves_before=$( pip_leaves --format 'freeze' )

        pip uninstall --yes --quiet "${package}"

        pip_leaves_after=$( pip_leaves --format 'freeze' )
        pip_leaves_diff=$( diff <( echo "${pip_leaves_before}" ) <( echo "${pip_leaves_after}" ) )

        # Turn the diff into a list of dependency packages which have now become leaves.
        typeset add_prefix='> '
        typeset -a pip_list_new_leaves=( ${${(M)${(f)pip_leaves_diff}:#${add_prefix}*}#${add_prefix}} )
        #                                          ^ Split into array on newlines.
        #                                     ^ Invert filtering.    ^ Filter out items *NOT* starting with '> '.
        #                                                                             ^ Strip '> ' prefix from all items.

        # If removing the package didn't create any new leaves, we're done.
        (( $#pip_list_new_leaves )) || continue

        # Call this function recursively for newly orphaned leaves.
        echo_log --level 'INFO' --indent ${indent} "Leaves created by removing '${package}': ${#pip_list_new_leaves}"
        echo_log --level 'INFO' --indent ${indent} "% ${0} ${pip_list_new_leaves[@]%==*}"
        ${0} --indent $(( indent + 1 )) ${pip_list_new_leaves}
    }
}

