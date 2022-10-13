#
# ZSHRC EXTENSION:
# Functions: VCS (git, etc)
#


#
#
#
function create_swift_gitignore() #
{
    curl -SLw "\n" "https://www.gitignore.io/api/swift,linux,xcode,macos,swiftpm,swiftpackagemanager" > .gitignore
}


#
#  Given a git repository URL (or the origin URL if no URL is specified), the
#  output will be a string of space-separated words representing the URL's
#  components with the following indices:
#
#       1) The total number of elements in the output
#       2) Combined URL "prefix": Scheme, [credentials,] host, [port,] and a trailing "/"
#       3) Scheme, or scp-style `ssh` user.  Schemes include 'http', 'https', and 'ssh'.  User is often 'git'.
#       4) Path.  Often (e.g., with Github), this will be the repository owner's username.
#       5) Repository name, with extension.  This is likely to end with '.git'.
#       6) Repository name
#
#  Example:
#       % repository='https://www.domain.net:8443/gituser/Project.git'
#       % components=($(git_repo_url_components "${repository}"))
#       % last_index=${components[1]}
#       % echo "All components: ${components}"
#       % echo "Last component (repository name): ${components[$last_index]}"
#  Output:
#       All components: 6 https://www.domain.net:8443/ https gituser Project.git Project
#       Last component (repository name): Project
#
function git_repo_url_components() # [repo_url]
{
    typeset repo_url="${1}" ; [[ -n "${repo_url}" ]] ||
    {
        repo_url=$(git remote get-url 'origin') || fail 'Repository URL was not provided, and could not be determined from origin remote.' $?
    }

    # Example URL formats:
    #      https: https://domain.com/foo/bar/Project.git (also covers)
    #   ssh(scp): user@domain.com:foo/bar/Project.git

    typeset    search='((https?|ssh):\/\/.+\..+?\/|(.+?)@.+\..+?\:)(.+)\/((.+)\.git)'
    typeset -a replace_elements=( \$1 \$2\$3 \$4 \$5 \$6 )  # Number of items in this array establishes the expected output element count.
    typeset    output_count=$(( $#replace_elements + 1 ))   # Adding one, because this parameter will be added to the array below.

    replace_elements=( "${output_count}" ${replace_elements[*]} )

    components=( $( perl -pe "s/${search}/${replace_elements[*]}/" <<< "${repo_url}" ) )

    [[     ${#components}    -eq  ${output_count}    ]] || fail "Parse error: incorrect number of elements (expected ${output_count}, found ${#components})."                              100
    [[     ${components[1]}  -eq  ${output_count}    ]] || fail "Parse error: incorrect element count in output (expected ${output_count}, found '${components[1]}')."                     103
    [[ -n "${components[3]}"                         ]] || fail "Parse error: Scheme length is zero."                                                                                      109
    [[    "${components[2]}" ==  "${components[3]}"* ]] || fail "Parse error: URL prefix does not begin with scheme (scheme: '${components[3]}', prefix: '${components[2]}')."             106
    [[ -n "${components[4]}"                         ]] || fail "Parse error: Path length is zero."                                                                                        112
    [[ -n "${components[6]}"                         ]] || fail "Parse error: Repository name length is zero."                                                                             118
    [[    "${components[5]}" ==  "${components[6]}"* ]] || fail "Parse error: Repo name+extension does not begin with repo name (name+ext: '${components[5]}', name: '${components[6]}')." 115

    echo "${components[*]}"
}


#
#  Given an owner username and a repository URL, add an remote named "blessed"
#  with a URL created by substituting the specified owner for the owner present
#  in the original URL.
#
function git_add_blessed_remote_with_owner() # <blessed_owner> [blessed_url]
{
    git remote get-url 'blessed' &>/dev/null && { fail "Unable to add 'blessed' remote: a remote already exists with that name." $? }

    typeset blessed_owner="${1}" ; [[ -n "${blessed_owner}" ]] || fail 'Argument for blessed repository owner username is missing or empty.' 10
    typeset blessed_url="${2}"

    [[ -z "${blessed_url}" ]] &&
    {
        typeset origin_url && origin_url=$(git remote get-url origin) && [[ -n "${origin_url}" ]] || fail "Unable to get url for 'origin' remote." 20
        typeset components && components=( $(git_repo_url_components "${origin_url}") )           || fail "Could not parse components for '${origin_url}'." 23
        typeset prefix=${components[2]}
        typeset repo_and_ext=${components[5]}

        blessed_url="${prefix}${blessed_owner}/${repo_and_ext}"
    }

    git remote add blessed "${blessed_url}" || fail "Unable to add 'blessed' remote." $?
    echo

    git remote -v
    echo
}


#
#  With a single command, clone the specified URL, then `cd` into the
#  cloned repo directory.
#
#  <repo_dir> : Optional.  Specifies the name of the repository directory which
#  will be created by the `git clone` operation.
#
function git_clone_cd() # <repo_url> [<repo_dir>]
{
    [[ -n "${1}" ]] || fail 'Argument for repository URL is missing or empty.' 10

    if [[ -n "${2}" ]] ; then
        git clone "${1}" ${~"${2}"} || fail "Unable to clone repository at ${1}" $?
    else
        git clone "${1}" || fail "Unable to clone repository at ${1}" $?
    fi

    cd ${${2}:-${1:t:r}}    || { echo_log "Unable to change working directory to ${1:t:r}" WARNING ; return 30 ; }
}


#
#  Clone the specified fork repository, `cd` into the cloned repo directory,
#  and add an upstream "blessed" remote for a repo of the same name belonging
#  to the specified owner.
#
#  <repo_dir> : Optional.  Specifies the name of the repository directory which
#  will be created by the `git clone` operation.
#
function git_clone_fork_with_parent_owner() # <fork_repo_url> <blessed_repo_owner> [<repo_dir>]
{
    [[ -n "${1}" ]] || fail 'Argument for repository URL is missing or empty.' 10
    [[ -n "${2}" ]] || fail 'Argument for blessed repository owner username is missing or empty.' 20

    echo
    { git_clone_cd "${1}" ${~"${3}"} && git_add_blessed_remote_with_owner "${2}" ; } || fail "The repository was cloned, but the 'blessed' remote could not be added." 40
}


#
#  Clone the specified repository hosted on github.com, and `cd` into the
#  cloned repo directory.  If the cloned repository is a fork, an upstream
#  "blessed" remote will be added dynamically by fetching the owner of the
#  fork's parent repository via the Github API.
#
#  <repo_dir> : Optional.  Specifies the name of the repository directory which
#  will be created by the `git clone` operation.
#
function github_clone() # <repo_url> [<repo_dir>]
{
    [[ -n "${GITHUB_ACCESS_TOKEN}" ]] || fail "Unable to continue: Shell parameter 'GITHUB_ACCESS_TOKEN' is unset or empty."  5

    typeset repo_url="${1}" ; [[ -n "${repo_url}" ]] || fail 'Argument for repository URL is missing or empty.' 10
    typeset repo_dir=${~"${2}"}
    typeset -a components && components=( $(git_repo_url_components "${repo_url}") ) || fail "Could not parse owner for '${repo_url}'."         20
    typeset repo_owner=${components[4]}
    typeset repo_name=${components[6]}
    typeset github_api='https://api.github.com/graphql'
    typeset query_json='{ "query": "query { repository(owner: \"'${repo_owner}'\" name: \"'${repo_name}'\") { parent { owner { login } } } }" }'

    typeset api_response && api_response=$( curl --fail --silent --show-error                             \
                                                --request 'POST' "${github_api}"                          \
                                                --header  "Authorization: Bearer ${GITHUB_ACCESS_TOKEN}"  \
                                                --header  'Content-Type: application/json; charset=utf-8' \
                                                --data    "${query_json}" ) && [[ -n "${api_response}" ]] || fail "Unable to fetch repo info from GitHub API." 40

    typeset parent_owner=$( jq --raw-output '.data.repository.parent.owner.login' <<< "${api_response}" )

    [[ ${parent_owner} == 'null' ]] &&
    {
        git_clone_cd "${repo_url}" "${repo_dir}"
        return
    }

    git_clone_fork_with_parent_owner "${repo_url}" "${parent_owner}" "${repo_dir}"
}


#
#  Pull changes into all branches from the specified upstream remote, and push
#  them to the specified origin remote.
#
function git_remote_sync() # [--all] <pull_from_remote_name> [push_to_remote_name]
{
    typeset -i fetch_all_branches=0

    [[ "${1}" = '--all' ]] && { validate_only=1 ; shift }

    typeset -r default_pull_remote="origin"
    typeset pull_remote="${1}" ; [[ -n "${pull_remote}" ]] ||
    {
        pull_remote="${default_pull_remote}"
        echo_log "Using default ('${pull_remote}') as name for pull remote." INFO ;
    }
    typeset push_remote="${2}"
    
    typeset -a branch_names=( $(git branch --format '%(refname:short)') )
    (( fetch_all_branches )) && branch_names=( $(git ls-remote --heads "${pull_remote}" | awk -F 'refs\\/heads\\/' '{print $2}') )

    echo_log

    for branch ( ${branch_names[@]} )
    {
        echo_log "Checking out local '${branch}'... \c" INFO

        git checkout "${branch}" &>/dev/null ||
        {
            echo -n "not found.  Fetching '${pull_remote}'... " 1>&2
            { git fetch ${pull_remote} ${branch} &>/dev/null && git checkout -b "${branch}" --track "${pull_remote}/${branch}" &>/dev/null } || { echo 1>&2 ; fail "Unable to checkout '${branch}'." 30 ; }
        }

        echo -n "complete.  Pulling '${branch}'... " 1>&2

        [[ -z "$(git --no-pager log "^${pull_remote}/${branch}" "${branch}")" ]] || { echo 1>&2 ; fail "Local repository has unpushed commits for branch '${branch}'." 40 ; }

        git pull --tags --force --no-edit "${pull_remote}" "${branch}" &>/dev/null || { echo 1>&2 ; fail "Unable to pull changes from '${pull_remote}' into local '${branch}'." 50 ; }

        [[ -n "${push_remote}" ]] && { git push --tags "${push_remote}" "${branch}" &>/dev/null || { echo 1>&2 ; fail "Unable to push changes to '${push_remote}' for '${branch}'." 60 ; } }

        echo "done.\n" 1>&2
    }
}


#
#  Print the name of the current branch, with no additional decoration.
#
function git_current_branch()
{
    git rev-parse --abbrev-ref 'HEAD'
}


#
#  Sync current branch changes to any branch which is a "sub-branch" of the
#  current branch, i.e., its name starts with the name of the current branch,
#  followed by a period, and an additional identifying string.
#
#  For any branch which has been pushed to an identically-named branch in the
#  specified remote, the changes will also be pushed to the remote.
#
function git_sync_to_subbranches_and_push # <remote>
{
    git fetch --all --quiet || return $?

    typeset parent_branch="$(git_current_branch)"
    typeset -a all_refs=( $(git for-each-ref --format '%(refname)') )
    typeset -a local_refs=( ${(M)all_refs:#refs/heads/${parent_branch}*} )

    typeset remote="$1"
    typeset -a remote_refs=()
    [[ -n "${remote}" ]] && remote_refs=( ${(M)all_refs:#refs/remotes/${remote}/${parent_branch}*} )

    for local_ref ( $local_refs[@] )
    {
        local_branch=${local_ref#refs/heads/}

        echo_log "Starting sync for '${local_branch}'..." INFO
        git checkout --quiet "${local_branch}" || return $?

        # Skip merging the parent into itself.
        [[ "${local_branch}" != "${parent_branch}" ]] &&
        {
            echo_log "... Merging '${parent_branch}' into '${local_branch}'..." INFO
            git merge --quiet --no-edit "${parent_branch}" || return $?
        }

        # We're done if the given remote name doesn't match any remote refs
        (( $#remote_refs )) || continue

        # Check for a matching remote branch; if none, we're done.
        remote_ref="refs/remotes/${remote}/${local_branch}"
        [[ ${remote_refs[(ie)$remote_ref]} -le ${#remote_refs} ]] || continue

        # Pull and push changes for remote.
        echo_log "... Pushing '${local_branch}' to '${remote}'..." INFO
        git pull --quiet --no-edit "${remote}" "${local_branch}" || return $?
        git push --quiet "${remote}" "${local_branch}" || return $?
    }

    # Checkout the branch where we started
    git checkout --quiet "${parent_branch}" || return $?

    # Check for remote refs that aren't local (so didn't get synced)
    # We're done if the given remote name doesn't match any remote refs
    (( $#remote_refs )) || return

    for remote_ref ( $remote_refs[@] )
    {
        # Run the inverse check from above... remote branch not found locally.
        remote_branch=${remote_ref#refs/remotes/${remote}/}
        local_ref="refs/heads/${remote_branch}"

        [[ ${local_refs[(ie)$local_ref]} -le ${#local_refs} ]] ||
        {
            echo_log "Changes will not be synced to remote branch '${remote_branch}', because it has not been checked out locally." WARNING
        }
    }
}

