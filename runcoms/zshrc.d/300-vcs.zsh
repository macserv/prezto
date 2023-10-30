##
##  ZSHRC EXTENSION:
##  Functions: VCS (git, etc)
##


typeset -gx GIT_COMMIT_JIRA_ISSUE
typeset -gx GIT_COMMIT_JIRA_ISSUE_CACHE="${HOME}/.cache/git_commit_jira_id.txt"


##
##  Print the name of the current branch, with no additional decoration.
##
function git_current_branch ()
{
    git rev-parse --abbrev-ref 'HEAD'
}


##
##  Print the name of each git ref in the current repo, one ref per line.
##
function git_all_refnames ()
{
    git for-each-ref --format '%(refname)'
}


##
##  Print all tags at the current HEAD, one per line.
##
function git_all_tags ()
{
    git --no-pager tag --points-at HEAD 2>/dev/null
}


##
##
##
function git_reset_local_branch_to_remote ()  # <remote>
{
    git fetch "${1}"
    git reset --hard "${1}/$(git_current_branch)"
}


##
##  Identify files which are currently being tracked, but should be
##  ignored based on `.gitignore` rules.  There are two common cases for this:
##  1. The file was added before a `.gitignore` rule was established.
##  2. The file was added using `git add --force` to override `.gitignore`.
##
function git_stowaways ()
{
    git ls-files --cached --ignored --exclude-standard
}


##
##  Given a git repository URL (or the origin URL if no URL is specified), the
##  output will be a string of space-separated words representing the URL's
##  components with the following indices:
##
##       1) The total number of elements in the output
##       2) Combined URL "prefix": Scheme, [credentials,] host, [port,] and a trailing "/"
##       3) Scheme, or scp-style `ssh` user.  Schemes include 'http', 'https', and 'ssh'.  User is often 'git'.
##       4) Path.  Often (e.g., with Github), this will be the repository owner's username.
##       5) Repository name, with extension.  This is likely to end with '.git'.
##       6) Repository name
##
##  Example:
##       % repository='https://www.domain.net:8443/gituser/Project.git'
##       % components=($(git_repo_url_components "${repository}"))
##       % last_index=${components[1]}
##       % echo "All components: ${components}"
##       % echo "Last component (repository name): ${components[$last_index]}"
##  Output:
##       All components: 6 https://www.domain.net:8443/ https gituser Project.git Project
##       Last component (repository name): Project
##
function git_repo_url_components ()  # [repo_url]
{
    typeset repo_url="${1}" ; [[ -n "${repo_url}" ]] ||
    {
        repo_url=$(git remote get-url 'origin') || { echo_log --level 'ERROR' 'Repository URL was not provided, and could not be determined from origin remote.' ; return $? ; }
    }

    # Example URL formats:
    #      https: https://domain.com/foo/bar/Project.git (also covers)
    #   ssh(scp): user@domain.com:foo/bar/Project.git

    typeset    search='((https?|ssh):\/\/.+\..+?\/|(.+?)@.+\..+?\:)(.+)\/((.+)\.git)'
    typeset -a replace_elements=( \$1 \$2\$3 \$4 \$5 \$6 )  # Number of items in this array establishes the expected output element count.
    typeset    output_count=$(( $#replace_elements + 1 ))   # Adding one, because this parameter will be added to the array below.

    replace_elements=( "${output_count}" ${replace_elements[*]} )

    components=( $( perl -pe "s/${search}/${replace_elements[*]}/" <<< "${repo_url}" ) )

    [[     ${#components}    -eq  ${output_count}    ]] || { echo_log --level 'ERROR' "Parse error: incorrect number of elements (expected ${output_count}, found ${#components})."                              ; return 100 ; }
    [[     ${components[1]}  -eq  ${output_count}    ]] || { echo_log --level 'ERROR' "Parse error: incorrect element count in output (expected ${output_count}, found '${components[1]}')."                     ; return 103 ; }
    [[ -n "${components[3]}"                         ]] || { echo_log --level 'ERROR' 'Parse error: Scheme length is zero.'                                                                                      ; return 109 ; }
    [[    "${components[2]}" ==  "${components[3]}"* ]] || { echo_log --level 'ERROR' "Parse error: URL prefix does not begin with scheme (scheme: '${components[3]}', prefix: '${components[2]}')."             ; return 106 ; }
    [[ -n "${components[4]}"                         ]] || { echo_log --level 'ERROR' 'Parse error: Path length is zero.'                                                                                        ; return 112 ; }
    [[ -n "${components[6]}"                         ]] || { echo_log --level 'ERROR' 'Parse error: Repository name length is zero.'                                                                             ; return 118 ; }
    [[    "${components[5]}" ==  "${components[6]}"* ]] || { echo_log --level 'ERROR' "Parse error: Repo name+extension does not begin with repo name (name+ext: '${components[5]}', name: '${components[6]}')." ; return 115 ; }

    echo "${components[*]}"
}


##
##  Given an owner username and a repository URL, add an remote named "blessed"
##  with a URL created by substituting the specified owner for the owner present
##  in the original URL.
##
function git_add_blessed_remote_with_owner ()  # <blessed_owner> [blessed_url]
{
    git remote get-url 'blessed' &>/dev/null && { echo_log --level 'ERROR' "Unable to add 'blessed' remote: a remote already exists with that name." ; return $? ; }

    typeset blessed_owner="${1}" ; [[ -n "${blessed_owner}" ]] || { echo_log --level 'ERROR' 'Argument for blessed repository owner username is missing or empty.' ; return 10 ; }
    typeset blessed_url="${2}"

    [[ -z "${blessed_url}" ]] &&
    {
        typeset origin_url && origin_url=$(git remote get-url origin) && [[ -n "${origin_url}" ]] || { echo_log --level 'ERROR' "Unable to get url for 'origin' remote." ; return 20 ; }
        typeset components && components=( $(git_repo_url_components "${origin_url}") )           || { echo_log --level 'ERROR' "Could not parse components for '${origin_url}'." ; return 23 ; }
        typeset prefix=${components[2]}
        typeset repo_and_ext=${components[5]}

        blessed_url="${prefix}${blessed_owner}/${repo_and_ext}"
    }

    git remote add blessed "${blessed_url}" || { echo_log --level 'ERROR' "Unable to add 'blessed' remote." ; return $? ; }
    echo

    git remote -v
    echo
}


##
##  With a single command, clone the specified URL, then `cd` into the
##  cloned repo directory.
##
##  <repo_dir> : Optional.  Specifies the name of the repository directory which
##  will be created by the `git clone` operation.
##
function git_clone_cd ()  # <repo_url> [<repo_dir>]
{
    [[ -n "${1}" ]] || { echo_log --level 'ERROR' 'Argument for repository URL is missing or empty.' ; return 10 ; }

    if [[ -n "${2}" ]] ; then
        git clone "${1}" ${~"${2}"} || { echo_log --level 'ERROR' "Unable to clone repository at ${1}" ; return $? ; }
    else
        git clone "${1}" || { echo_log --level 'ERROR' "Unable to clone repository at ${1}" ; return $? ; }
    fi

    cd ${${2}:-${1:t:r}}    || { echo_log --level 'WARNING' "Unable to change working directory to ${1:t:r}" ; return 30 ; }
}


##
##  Clone the specified fork repository, `cd` into the cloned repo directory,
##  and add an upstream "blessed" remote for a repo of the same name belonging
##  to the specified owner.
##
##  <repo_dir> : Optional.  Specifies the name of the repository directory which
##  will be created by the `git clone` operation.
##
function git_clone_fork_with_parent_owner ()  # <fork_repo_url> <blessed_repo_owner> [<repo_dir>]
{
    [[ -n "${1}" ]] || { echo_log --level 'ERROR' 'Argument for repository URL is missing or empty.' ; return 10 ; }
    [[ -n "${2}" ]] || { echo_log --level 'ERROR' 'Argument for blessed repository owner username is missing or empty.' ; return 20 ; }

    echo
    { git_clone_cd "${1}" ${~"${3}"} && git_add_blessed_remote_with_owner "${2}" ; } || { echo_log --level 'ERROR' "The repository was cloned, but the 'blessed' remote could not be added." ; return 40 ; }
}


##
##  Clone the specified repository hosted on github.com, and `cd` into the
##  cloned repo directory.  If the cloned repository is a fork, an upstream
##  "blessed" remote will be added dynamically by fetching the owner of the
##  fork's parent repository via the Github API.
##
##  <repo_dir> : Optional.  Specifies the name of the repository directory which
##  will be created by the `git clone` operation.
##
function github_clone ()  # <repo_url> [<repo_dir>]
{
    [[ -n "${GITHUB_ACCESS_TOKEN}" ]] || { echo_log --level 'ERROR' "Unable to continue: Shell parameter 'GITHUB_ACCESS_TOKEN' is unset or empty." ; return 5 ; }

    typeset repo_url="${1}" ; [[ -n "${repo_url}" ]] || { echo_log --level 'ERROR' 'Argument for repository URL is missing or empty.' ; return 10 ; }
    typeset repo_dir=${~"${2}"}
    typeset -a components && components=( $(git_repo_url_components "${repo_url}") ) || { echo_log --level 'ERROR' "Could not parse owner for '${repo_url}'." ; return 20 ; }
    typeset repo_owner=${components[4]}
    typeset repo_name=${components[6]}
    typeset github_api='https://api.github.com/graphql'
    typeset query_json='{ "query": "query { repository(owner: \"'${repo_owner}'\" name: \"'${repo_name}'\") { parent { owner { login } } } }" }'

    typeset api_response && api_response=$( curl --fail --silent --show-error                             \
                                                --request 'POST' "${github_api}"                          \
                                                --header  "Authorization: Bearer ${GITHUB_ACCESS_TOKEN}"  \
                                                --header  'Content-Type: application/json; charset=utf-8' \
                                                --data    "${query_json}" ) && [[ -n "${api_response}" ]] || { echo_log --level 'ERROR' "Unable to fetch repo info from GitHub API." ; return 40 ; }

    typeset parent_owner=$( jq --raw-output '.data.repository.parent.owner.login' <<< "${api_response}" )

    [[ ${parent_owner} == 'null' ]] &&
    {
        git_clone_cd "${repo_url}" "${repo_dir}"
        return
    }

    git_clone_fork_with_parent_owner "${repo_url}" "${parent_owner}" "${repo_dir}"
}


##
##  Pull changes into local branches from a given upstream remote, creating
##  tracking branches for any remote branches that do not exist locally.
##
##  Optionally, push changes to the same branches on a given downstream remote.
##
##  ARGUMENTS
##  ---------
##  <upstream_remote> : The name of the remote from which changes will be pulled
##      into the local working copy.  Default: 'origin'
##
##  [downstream_remote] : Optional.  If specified, each pulled branch will also
##      be pushed to the same branch on this remote.
##
function git_remote_sync ()  # <upstream_remote> [downstream_remote]
{
    typeset -r default_upstream_remote="origin"
    typeset upstream_remote="${1}" ; [[ -n "${upstream_remote}" ]] ||
    {
        upstream_remote="${default_upstream_remote}"
        echo_log --level 'INFO' "Using default ('${upstream_remote}') as name for upstream remote." ;
    }
    typeset downstream_remote="${2}"
    typeset starting_branch=$( git_current_branch )
    typeset -a branch_names=( $(git ls-remote --heads "${upstream_remote}" | awk -F 'refs\\/heads\\/' '{print $2}') )

    echo_log

    for branch ( ${branch_names[@]} )
    {
        echo_log -n --level 'INFO' "Switching to '${branch}'... "

        git switch "${branch}" &>/dev/null ||
        {
            echo_err -n "Creating local, tracking '${upstream_remote}'... "
            git switch --track "${upstream_remote}/${branch}" &>/dev/null || { echo_err ; echo_log --level 'ERROR' "Unable to create local '${branch}' tracking '${upstream_remote}'." ; return 30 ; }
        }

        echo_err -n "switched.  Pulling changes from '${upstream_remote}'... "

        [[ -z "$(git --no-pager log "^${upstream_remote}/${branch}" "${branch}")" ]]   || { echo_err ; echo_log --level 'ERROR' "Local repository has unpushed commits for branch '${branch}'." ; return 40 ; }
        git pull --tags --force --no-ff --no-edit "${upstream_remote}" "${branch}" &>/dev/null || { echo_err ; echo_log --level 'ERROR' "Unable to pull changes from '${upstream_remote}' into local '${branch}'." ; return 50 ; }

        # If no downstream remote was specified, move on to the next branch.
        [[ -z "${downstream_remote}" ]] &&
        {
            echo_err "done."
            continue
        }

        # Push to specified remote.
        echo_err -n "complete.  Pushing to '${downstream_remote}'... "
        git push --tags "${downstream_remote}" "${branch}" &>/dev/null || { echo_err ; echo_log --level 'ERROR' "Unable to push changes to '${downstream_remote}' for '${branch}'." ; return 60 ; }
        echo_err "done."
    }

    git switch ${starting_branch} &>/dev/null
}


##
##  Synchronize changes to any branch which is a "sub-branch" of the current
##  branch.  A sub-branch is a branch whose name starts with the name of the
##  current branch, followed by a period, and an additional identifying string.
##
##  ARGUMENTS
##  ---------
##  [downstream_remote] : Optional.  If specified, each pulled branch will also
##      be pushed to the same branch on this remote.
##
##  EXAMPLE:
##  * `foo/bar` (parent)
##      * `foo/bar.baz` (sub-branch)
##      * `foo/bar.bat` (sub-branch)
##      * `foo/bar.boom` (sub-branch)
##
function git_sync_to_subbranches_and_push ()  # [remote]
{
    git fetch --all --quiet || { echo_log --level 'ERROR' "Unable to fetch branches." ; return $? ; }

    typeset            remote="${1:-origin}"
    typeset     parent_branch="$(git_current_branch)"
    typeset remote_ref_prefix="refs/remotes/${remote}/"
    typeset  local_ref_prefix='refs/heads/'

    typeset -a         all_refs=( $(git_all_refnames) )
    typeset -a      remote_refs=( ${(M)all_refs:#${remote_ref_prefix}${parent_branch}*} )
    typeset -a       local_refs=( ${(M)all_refs:#${local_ref_prefix}${parent_branch}*} )
    typeset -U all_branch_names=( ${remote_refs#${remote_ref_prefix}} ${local_refs#${local_ref_prefix}} )

    typeset -i branch_is_remote
    typeset -i branch_is_local

    for branch_name ( ${(i)all_branch_names[@]} )
    {
        branch_is_remote=${#${(M)remote_refs%/${branch_name}}}
        branch_is_local=${#${(M)local_refs%/${branch_name}}}

        # Checkout the branch, with remote reference if necessary.
        echo_log --level 'INFO' "Checking out '${branch_name}'..."
        (( branch_is_remote && (! branch_is_local) )) && { git switch --quiet --create "${branch_name}" "${remote_ref_prefix}${branch_name}" || { echo_log --level 'ERROR' "Unable to check out branch." ; return 1 ; } }
        (( branch_is_local ))                         && { git switch --quiet          "${branch_name}"                                      || { echo_log --level 'ERROR' "Unable to check out branch." ; return 1 ; } }

        # Pull upstream changes for remote branches.
        (( branch_is_remote )) &&
        {
            echo_log --level 'INFO' --indent 1 "Pulling changes from '${remote}'..."
            git pull --quiet --no-edit "${remote}" "${branch_name}" || { echo_log --level 'ERROR' "Unable to pull changes." ; return 1 ; }
        }

        # Merge changes from parent branch, skipping the parent branch itself.
        [[ "${branch_name}" != "${parent_branch}" ]] &&
        {
            echo_log --level 'INFO' --indent 1 "Merging '${parent_branch}' into '${branch_name}'..."
            git merge --quiet --no-edit "${parent_branch}" || { echo_log --level 'ERROR' "Unable to merge." ; return 1 ; }
        }

        # Push changes for remote branches.
        (( branch_is_remote )) &&
        {
            echo_log --level 'INFO' --indent 1 "Pushing '${branch_name}' to '${remote}'..."
            git push --quiet "${remote}" "${branch_name}" || { echo_log --level 'ERROR' "Unable to push changes." ; return 1 ; }
        }
    }

    # Check out parent branch so we end where we started.
    git checkout --quiet "${parent_branch}" || return $?
}


##
##  Streamline commits related to a specific JIRA issue ID.
##
function git_commit_jira ()  # [(-i | --id) <jira_id>] [message]
{
    typeset help
    typeset jira_id

    zparseopts -D -E -F -K -- \
        {h,-help}=help \
        {i,-id}:=jira_id \
    || return 1

    # If the 'help' flag is set, display this function's usage text.
    if (( $#help )); then
        print -rC1 -- \
            "$0 [-h | --help]" \
            "$0 [-i | --id <jira_id>] <message>"
        return
    fi

    # Get the Jira ID, trying argument, env var, and cache file.
    (( $#jira_id ))       && jira_id="${jira_id[2]}"
    [[ -n "${jira_id}" ]] || jira_id="${GIT_COMMIT_JIRA_ISSUE}"
    [[ -n "${jira_id}" ]] || { jira_id=$( < "${GIT_COMMIT_JIRA_ISSUE_CACHE}" ) 2>/dev/null ; }
    [[ -n "${jira_id}" ]] || { echo_log --level 'ERROR' "JIRA issue ID not found in command argument, environment, or cache." ; return 10 ; }

    # Update the env var and cache file.
    typeset -gx GIT_COMMIT_JIRA_ISSUE="${jira_id}"
    echo "${jira_id}" >! "${GIT_COMMIT_JIRA_ISSUE_CACHE}"

    typeset -a commit_cmd=( 'git' 'commit' )
    typeset message="${1}"

    [[ -n "${message}" ]] ||
    {
        echo_log --level 'INFO' "No commit message was provided, so no changes will be committed.  Current JIRA issue ID is '${jira_id}'."
        return 0
    }

    git commit -m "${message}  (${jira_id})"
}


##
##  Update commit pointer for a tag by deleting and recreating it.
##
function git_move_tag ()  # [--all-remotes] [--remote <remote_name>] <tag_name>
{
    ## Create usage output.
    typeset usage=(
        "$0 [--help | -h | -?]"
        "$0 [--all-remotes [--remote <remote_name>] ... <tag_name>"
    )

    ## Define options array with defaults.
    typeset -a all_remotes=( $( git remote ) )
    typeset -U arg_remotes=( '--remote' )

    ## Configure parser and process function arguments.
    typeset -a parse_config=(
    #   '-a' 'options' # Specifies a default array to contain recognized options.
    #   '-A' 'options' # Same as -a, but using an associative array. Test: (( ${+options[--foo]} ))
        '-D'           # Remove found options from the positional parameters array ($@).
    #   '-E'           # Don't stop at the first string that isn't described by the specs.
        '-F'           # Stop and exit if a param is found which is not in the specs.
        '-K'           # Don't replace existing arrays (allows default values).
    #   '-M'           # Allows the 'name' in '=name' to reference another spec.
        '--'           # Indicates that options end here and spec starts.
        '-help=arg_help' 'h=arg_help' '?=arg_help'
        '-all-remotes=arg_all_remotes'
        '-remote+:=arg_remotes'
    )

    ## Load parser and process function arguments.
    zmodload zsh/zutil && zparseopts ${parse_config[@]} || { echo_log --level 'ERROR' 'Failed to load or configure zparseopts command.' ; return $? ; }

    ## Display usage if help flag is set.
    (( ${#arg_help} )) && { print -l $usage && return 0; }

    typeset tag_name="${1}"
    [[ -n "${tag_name}" ]] || { echo_log --level 'ERROR' "Missing argument for tag name." ; return 1 ; }

    typeset -a remotes=()

    (( ${#arg_remotes} > 1 )) && remotes=( ${arg_remotes:1} )
    (( ${#arg_all_remotes} )) && remotes=( ${all_remotes} )

    # REMOVE LWC TAG
    echo_debug "Moving tag '${tag_name}' in local working copy to commit '$( git rev-parse --short HEAD )'..."
    git tag --delete "${tag_name}" &>/dev/null || { echo_log --level 'ERROR' "Unable to delete tag '${tag_name}' from local working copy." ; return $? ; }
    git tag "${tag_name}"                      || { echo_log --level 'ERROR' "Unable to create tag '${tag_name}' in local working copy."   ; return $? ; }

    # REMOVE TAG FROM REMOTES
    for remote ( ${remotes} )
    {
        echo_debug "Moving tag '${tag_name}' in remote '${remote}'..."
        git push "${remote}"                      ":refs/tags/${tag_name}" &>/dev/null || { echo_log --level 'ERROR' "Unable to delete tag '${tag_name}' from remote '${remote}'." ; return $? ; }
        git push "${remote}" "refs/tags/${tag_name}:refs/tags/${tag_name}" &>/dev/null || { echo_log --level 'ERROR' "Unable to create tag '${tag_name}' in remote '${remote}'."   ; return $? ; }
    }
}


##
##  Add blessed remote branch refs for pull request branches in a Bitbucket repository.
##
function git_add_bitbucket_pull_request_refs
{
    git config --add remote.blessed.fetch '+refs/pull-requests/*/from:refs/remotes/upstream/pull-requests/*'
    git fetch blessed
}


