################################################################################
#  FUNCTIONS: VCS (git, etc)


#
#
#
function mkswiftgitignore() #
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
function git-repo-url-components() # <repo_url>
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
function git-add-blessed-remote-with-owner() # <blessed_owner> <blessed_url>
{
    git remote get-url blessed > /dev/null 2>&1 && fail "Unable to add 'blessed' remote: a remote already exists with that name." $?
    
    local blessed_owner blessed_url
    
    blessed_owner="${1}" ; [[ -n "${blessed_owner}" ]] || fail 'Argument for blessed repository owner username is missing or empty.' 10
    blessed_url="${2}"
    
    [[ -z "${blessed_url}" ]] &&
    {
        local origin_url components prefix repo_and_ext
        
        origin_url=$(git remote get-url origin) && [[ -n "${origin_url}" ]] || fail "Unable to get url for 'origin' remote." 20
        components=( $(git-repo-url-components "${origin_url}") )           || fail "Could not parse components for '${origin_url}'." 23
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
function git-clone-cd() # <repo_url>
{
    [[ -n "${1}" ]] || fail 'Argument for repository URL is missing or empty.' 10

    git clone "${1}" || fail "Unable to clone repository at ${1}" 20
    cd "${1:t:r}"    || { echo_log "Unable to change working directory to ${1:t:r}" WARNING ; return 30 ; }
}


#
#
#
function git-clone-fork-with-parent-owner() # <fork_repo_url> <blessed_repo_owner>
{
    [[ -n "${1}" ]] || fail 'Argument for repository URL is missing or empty.' 10
    [[ -n "${2}" ]] || fail 'Argument for blessed repository owner username is missing or empty.' 20
    
    echo
    { git-clone-cd "${1}" && git-add-blessed-remote-with-owner "${2}" } || fail "The repository was cloned, but the 'blessed' remote could not be added." 40
}


#
#
#
function github-clone() # <repo_url>
{
    [[ -n "${GITHUB_ACCESS_TOKEN}" ]] || fail "Unable to continue: Shell parameter 'GITHUB_ACCESS_TOKEN' is unset or empty."  5

    local repo_url components repo_owner repo_name github_api query_json api_response parent_owner
    
    repo_url="${1}" ; [[ -n "${repo_url}" ]]                || fail 'Argument for repository URL is missing or empty.' 10
    components=( $(git-repo-url-components "${repo_url}") ) || fail "Could not parse owner for '${repo_url}'."         20
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
        git-clone-fork-with-parent-owner "${repo_url}" "${parent_owner}"

    else
        git-clone-cd "${repo_url}"

    fi
}
