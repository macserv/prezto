################################################################################
#  FUNCTIONS: VCS (git, etc)


#
#
#
function create_swift_gitignore() #
{
    curl -SLw "\n" "https://www.gitignore.io/api/swift,linux,xcode,macos,swiftpm,swiftpackagemanager" > .gitignore
}


#
# With an argument, output will be a space-separated string containing
# these components at the following indices:
#
#       1) The total number of elements in the output
#       2) Combined URL "prefix": Scheme, [credentials,] host, [port,] and a trailing "/"
#       3) Scheme, or scp-style `ssh` user.  Schemes include 'http', 'https', and 'ssh'.  User is often 'git'.
#       4) Path.  Often (e.g., with Github), this will be the repository owner's username.
#       5) Repository name, with extension.  This is likely to end with '.git'.
#       6) Repository name
#
# Example:
#       % repository='https://www.domain.net:8443/gituser/Project.git'
#       % components=($(git-repo-url-components "${repository}"))
#       % last_index=${components[1]}
#       % echo "All components: ${components}"
#       % echo "Last component (repository name): ${components[$last_index]}"
# Output:
#       6 https://www.domain.net:8443/ https gituser Project.git Project
#       Repository name is: Project
#
function git_repo_url_components() # <repo_url>
{
    [[ -n "${1}" ]] || fail 'Argument for git repository URL is missing or empty.' 10

    local search replace_elements output_count

    # E.g.:  https: https://domain.com/foo/bar/Project.git (also covers)
    #     ssh(scp): user@domain.com:foo/bar/Project.git

    search='((https?|ssh):\/\/.+\..+?\/|(.+?)@.+\..+?\:)(.+)\/((.+)\.git)'
    replace_elements=( \$1 \$2\$3 \$4 \$5 \$6 )  # Number of items in this array establishes the expected output element count.
    output_count=$(( $#replace_elements + 1 ))   # Adding one, because this parameter will be added to the array below.
    
    replace_elements=( "${output_count}" ${replace_elements[*]} )
    
    components=( $( perl -pe "s/${search}/${replace_elements[*]}/" <<< "${1}" ) )
    
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
#
#
function git_add_blessed_remote_with_owner() # <blessed_owner> <blessed_url>
{
    git remote get-url blessed > /dev/null 2>&1 && fail "Unable to add 'blessed' remote: a remote already exists with that name." $?
    
    local blessed_owner blessed_url
    
    blessed_owner="${1}" ; [[ -n "${blessed_owner}" ]] || fail 'Argument for blessed repository owner username is missing or empty.' 10
    blessed_url="${2}"
    
    [[ -z "${blessed_url}" ]] &&
    {
        local origin_url components prefix repo_and_ext
        
        origin_url=$(git remote get-url origin) && [[ -n "${origin_url}" ]] || fail "Unable to get url for 'origin' remote." 20
        components=( $(git_repo_url_components "${origin_url}") )           || fail "Could not parse components for '${origin_url}'." 23
        prefix=${components[2]}
        repo_and_ext=${components[5]}
        
        blessed_url="${prefix}${blessed_owner}/${repo_and_ext}"
    }
    
    git remote add blessed "${blessed_url}" || fail "Unable to add 'blessed' remote." $?
    echo
    
    git remote -v
    echo
}


#
#
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
#
#
function git_clone_fork_with_parent_owner() # <fork_repo_url> <blessed_repo_owner> [<repo_dir>]
{
    [[ -n "${1}" ]] || fail 'Argument for repository URL is missing or empty.' 10
    [[ -n "${2}" ]] || fail 'Argument for blessed repository owner username is missing or empty.' 20
    
    echo
    { git_clone_cd "${1}" ${~"${3}"} && git_add_blessed_remote_with_owner "${2}" ; } || fail "The repository was cloned, but the 'blessed' remote could not be added." 40
}


#
#
#
function github_clone() # <repo_url> [<repo_dir>]
{
    [[ -n "${GITHUB_ACCESS_TOKEN}" ]] || fail "Unable to continue: Shell parameter 'GITHUB_ACCESS_TOKEN' is unset or empty."  5

    local repo_url repo_dir components repo_owner repo_name github_api query_json api_response parent_owner
    
    repo_url="${1}" ; [[ -n "${repo_url}" ]]                || fail 'Argument for repository URL is missing or empty.' 10
    repo_dir=${~"${2}"}
    components=( $(git_repo_url_components "${repo_url}") ) || fail "Could not parse owner for '${repo_url}'."         20
    repo_owner=${components[4]}
    repo_name=${components[6]}
    github_api='https://api.github.com/graphql'
    query_json='{ "query": "query { repository(owner: \"'${repo_owner}'\" name: \"'${repo_name}'\") { parent { owner { login } } } }" }'
    api_response=$( curl --fail --silent --show-error                              \
                               --request 'POST' "${github_api}"                          \
                               --header  "Authorization: Bearer ${GITHUB_ACCESS_TOKEN}"  \
                               --header  'Content-Type: application/json; charset=utf-8' \
                               --data    "${query_json}" ) && [[ -n "${api_response}" ]] || fail "Unable to fetch repo info from GitHub API." 40

    parent_owner=$( jq --raw-output '.data.repository.parent.owner.login' <<< "${api_response}" )
    
    if [[ ${parent_owner} != 'null' ]] ; then
        git_clone_fork_with_parent_owner "${repo_url}" "${parent_owner}" "${repo_dir}"

    else
        git_clone_cd "${repo_url}" "${repo_dir}"

    fi
}


#
# Pull all changes from upstream ("blessed") remote to the repo
# origin.
#
function git_fork_sync() # <upstream_remote> <origin_remote> 
{
    local default_origin  ;  default_origin="origin"
    local upstream_remote ; upstream_remote="${1}" ; [[ -n "${upstream_remote}" ]] || fail 'Argument for upstream remote name is missing or empty.' 20
    local origin_remote   ;   origin_remote="${2}" ; [[ -n "${origin_remote}"   ]] || { origin_remote="${default_origin}" ; echo_log "Using default ('${origin_remote}') as name for origin remote." INFO ; }
    
    echo


    for branch in $(git ls-remote --heads "${upstream_remote}" | awk -F 'refs\\/heads\\/' '{print $2}') ; do

        echo -n "Checking out '${branch}'... trying local... "

        git checkout "${branch}" &> /dev/null ||
        {
            echo -n "trying '${origin_remote}'... "
            { git fetch ${origin_remote} ${branch} &> /dev/null && git checkout -b "${branch}" --track "${origin_remote}/${branch}" &> /dev/null } ||
            {
                echo -n "using '${upstream_remote}'... "
                git fetch ${upstream_remote} ${branch} &> /dev/null && git checkout -b "${branch}" --track "${upstream_remote}/${branch}" &> /dev/null || { echo ; fail "Unable to checkout '${branch}'." 30 ; }
            }
        }
        
        echo -n "complete.  Syncing '${branch}'... "
        
        [[ -z "$(git --no-pager log "^${origin_remote}/${branch}" "${branch}")" ]] || { echo ; fail "Local repository has unpushed commits for branch '${branch}'." 40 ; }
        
        git pull "${upstream_remote}" "${branch}" &> /dev/null || { echo ; fail "Unable to pull changes from '${upstream_remote}' into '${branch}'." 50 ; }
        git push "${origin_remote}"   "${branch}" &> /dev/null || { echo ; fail "Unable to push changes to '${origin_remote}' for '${branch}'." 60 ; }
        
        echo "done."
        echo

    done
}


#
# Print only the name of the current branch, with no additional
# information or decoration.
#
function git_current_branch()
{
    git rev-parse --abbrev-ref 'HEAD'
}


#
# Sync current branch changes to any branch which is a "sub-branch" of the
# current branch, i.e., its name starts with the name of the current branch,
# followed by a period, and an additional identifying string.
#
# For any branch which has been pushed to an identically-named branch in the
# specified remote, the changes will also be pushed to the remote.
#
function git_sync_to_subbranches_and_push # <remote>
{
    local remote parent_branch
    local -a all_refs local_refs remote_refs

    git fetch --all || return $?
    
    parent_branch="$(git_current_branch)"
    all_refs=( $(git for-each-ref --format '%(refname)') )
    local_refs=( ${(M)all_refs:#refs/heads/${parent_branch}*} )

    remote="$1"
    remote_refs=()
    [[ -n "${remote}" ]] && remote_refs=( ${(M)all_refs:#refs/remotes/${remote}/${parent_branch}*} )

    for local_ref ( $local_refs[@] )
    {
        branch=${local_ref#refs/heads/}

        echo_log "Starting sync for '${branch}'..." INFO
        git checkout "${branch}" || return $?

        # Skip merging the parent into itself.
        [[ "${branch}" != "${parent_branch}" ]] &&
        {
            echo_log "... Merging '${parent_branch}' into '${branch}'..." INFO
            # git merge "${parent_branch}" || return $?
        }

        # We're done if the given remote name doesn't match any remote refs
        (( $#remote_refs )) || continue

        # Check for a matching remote branch; if none, we're done.
        remote_ref="refs/remotes/${remote}/${branch}"
        [[ ${remote_refs[(ie)$remote_ref]} -le ${#remote_refs} ]] || continue

        # Pull and push changes for remote.
        echo_log "... Pushing '${branch}' to '${remote}'..." INFO
        git pull "${remote}" "${branch}" || return $?
        # git push "${remote}" "${branch}" || return $?
    }

    # Check for remote refs that aren't local (so didn't get synced)
    # We're done if the given remote name doesn't match any remote refs
    (( $#remote_refs )) || return

    for remote_ref ( $remote_refs[@] )
    {
        branch=${remote_ref#refs/remotes/${remote}}

        # Run the inverse check from above... remote branch not found locally.
        local_ref="refs/heads/${branch}"
        [[ ${local_refs[(ie)$local_ref]} -le ${#local_refs} ]] ||
        {
            echo_log "Changes will not be synced to remote branch '${branch}', because it has not been checked out locally." WARNING
        }
    }
}

