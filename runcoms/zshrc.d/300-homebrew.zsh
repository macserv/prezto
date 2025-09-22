##
##  ZSHRC EXTENSION:
##  Functions: Homebrew
##



##
##  Uninstall all kegs.
##
##  --dry-run:  Skip actual keg removal.
##
function brew_uninstall_all_kegs  # [--dry-run]
{
    typeset -i dry_run=0 ; [[ "${1}" = '--dry-run' ]] && dry_run=1
    echo_log --level 'INFO' "Uninstalling all Homebrew kegs..."

    for keg ( $(brew list -1 --formulae) )
    {
        echo_log -n --level 'INFO' "Uninstalling keg '${keg}'..."
        (( dry_run )) && { echo_err ' skipped uninstalling (dry-run mode).' ; continue ; }
        brew uninstall --quiet --formula --ignore-dependencies "${keg}"
        echo_err ' uninstalled.'
    }
}


##
##  Perform a keg "reset", uninstalling all kegs, and re-installing leaves.
##
##  Useful for rebuilding the dependency tree, which can become inconsistent
##  and/or inaccurate over time.
##
##  --dry-run:  Skip actual keg removal, reinstallation, and cleanup actions.
##
function brew_reinstall_leaves  # [--dry-run]
{
    typeset -i dry_run=0 ; [[ "${1}" = '--dry-run' ]] && dry_run=1
    typeset -a brew_leaves && brew_leaves=( $( brew leaves ) ) || { echo_log --level 'ERROR' "Unable to get list of installed leaf kegs." ; return $? ; }

    brew_uninstall_all_kegs $@

    echo_log --level 'INFO' "Reinstalling the following \"leaf\" kegs:\n${(@j:\n:)brew_leaves/#/* }"
    (( dry_run )) && { echo_log --level 'INFO' "Skipped reinstalling and cleanup (dry-run mode)." ; return 0 ; }

    brew install --quiet --formula ${brew_leaves}
    brew cleanup
    brew doctor
}


##
##  Generate an image of the dependency tree for installed Homebrew kegs.
##
##  Required Packages:
##      brew install martido/brew-graph/brew-graph
##      brew install graphviz
##
##  --dot:  Output a ``.dot`` file instead of a ``.pdf`` file.
##  [package ...] :  List of packages to include in the graph.  Default: 'all'.
##
##  TODO: Allow any output format recognized by ``dot`` to be used.  Do this by
##  interpreting the output path extension, or with an explicit arument.
##  Default behavior is to output the entire Homebrew dependency tree to
##  `stdout` in `dot` format.
##
##  [--output <file_path>]:  Output to the specified `file_path`, or to
##      `stdout` if `-` is specified.
##
##      AUTOMATIC FORMAT DETERMINATION:  The following rules will be applied to
##      determine an output format.  The ``--format`` argument (below) can be
##      used to override this behavior.
##      | File Path                     | Output Format                                 |
##      |-------------------------------|-----------------------------------------------|
##      | `-`                           | Output to `stdout` in `dot` format.           |
##      | No extension                  | Output to `file_path` in `dot` format.        |
##      | Extension recognized by `dot` | Output to `file_path` in the matching format. |
##      | Extension not recognized      | ERROR: Return from function with status `1`.  |
##
##  [--format <format>]:  Use the specified output format, which must be one
##      recognized by ``dot``.
##
function brew_dependency_graph ()  # --dot [package ...]
{
    typeset -i convert_to_pdf=1
    [[ "${1}" == '--dot' ]] && { convert_to_pdf=0 ; shift ; }

    typeset dependency_name="${(j'-')@}"
    [[ -z "$dependency_name" ]] && dependency_name="all"

    # Write the ``.dot`` graph file to a temporary location.
    typeset tmp_dir && tmp_dir=$( new_tmp_dir ) || { echo_log --level 'ERROR' "Unable to create temporary directory." ; return $? ; }
    typeset file_stub="brew-dependencies-${dependency_name}"
    typeset dot_tmp_path="${tmp_dir}/${file_stub}.dot"

    brew graph --installed --highlight-leaves --highlight-outdated $@ > "${dot_tmp_path}" || { echo_log --level 'ERROR' "Unable to generate dependency graph." ; return $? ; }

    # If we're good with a ``.dot`` file, just return it.
    (( convert_to_pdf > 0 )) || { mv "${dot_tmp_path}" '.' ; return 0 ; }

    # Convert the ``.dot`` file to a ``.pdf`` file at the CWD.
    dot -Tpdf -o"./${file_stub}.pdf" "${dot_tmp_path}" || { echo_log --level 'ERROR' "Unable to convert DOT graph at '${dot_tmp_path}' to PDF." ; return $? ; }
}


##
##  Get options for installed package
##
##  Required Packages:
##      brew install jq
##
##  $1: Installed package name.
##
function brew_installed_options ()  # <package>
{
    [[ $# -ge 1 ]]  || fail 'Missing package name argument.' 10

    typeset installation_info=$(brew info --json=v1 $1)

    jq --raw-output ".[].installed[0].used_options | @sh" <<< "${installation_info}"
}


##
##  List all brew leaves with their description appended.
##
function brew_leaves_with_info ()
{
    for formula ( $(brew leaves) )
    {
        typeset description=$(brew info --json --formula "${formula}" | jq --raw-output '.[0].desc')
        echo "${formula} : ${description}"
    }
}


##
##  Remove a list of brew formulae, along with any formulae that are no longer
##  required by any other installed formulae.
##  TODO: Genericize this and ``pip_uninstall_leaves`` into a common function
##      which invokes package-manager-specific helper functions.
##
function brew_uninstall_leaves ()  # [--indent <level>] <formula ...>
{
    typeset -i indent=0
    [[ ${1} == '--indent' ]] && { indent=${2} ; shift 2 }

    typeset brew_leaves_before
    typeset brew_leaves_after
    typeset brew_leaves_diff

    for formula ( ${@} )
    {
        echo_log --level 'INFO' --indent ${indent} "Removing formula '${formula}'..."

        # Generate a `diff` of the "leaf" formula list, before and after removing the formula.
        brew_leaves_before=$( brew leaves )

        brew uninstall --quiet "${formula}"

        brew_leaves_after=$( brew leaves )
        brew_leaves_diff=$( diff <( echo "${brew_leaves_before}" ) <( echo "${brew_leaves_after}" ) )

        # Turn the diff into a list of dependency formulae which have now become leaves.
        typeset add_prefix='> '
        typeset -a brew_list_new_leaves=( ${${(M)${(f)brew_leaves_diff}:#${add_prefix}*}#${add_prefix}} )
        #                                          ^ Split into array on newlines.
        #                                     ^ Invert filtering.    ^ Filter out items *NOT* starting with '> '.
        #                                                                             ^ Strip '> ' prefix from all items.

        # If removing the formula didn't create any new leaves, we're done.
        (( $#brew_list_new_leaves )) || continue

        # Call this function recursively for newly orphaned leaves.
        echo_log --level 'INFO' --indent ${indent} "Leaves created by removing '${formula}': ${#brew_list_new_leaves}"
        echo_log --level 'INFO' --indent ${indent} "% ${0} ${brew_list_new_leaves[@]%==*}"
        ${0} --indent $(( indent + 1 )) ${brew_list_new_leaves}
    }
}

