##
##  ZSHRC EXTENSION:
##  Functions: Proxy Management
##


##
##  Configure proxy parameter names, without regard to capitalization.
##  NO_PROXY parameters will be handled differently, so they're in a separate
##  parameter list.  These values will be used to generate the uppercase and
##  lowercase parameter names later.
##
typeset -a PROXY_ENV_PARAMETER_NAMES=(
    'HTTP_PROXY'
    'HTTPS_PROXY'
    'ALL_PROXY'
)

typeset -a NOPROXY_ENV_PARAMETER_NAMES=(
    'NO_PROXY'
)


##
##  Generate a "universally" formatted value for use with the global `no_proxy`
##  parameter for proxy bypass in the shell.  Output format will be governed by
##  the following guidelines and assumptions:
##
##  * Use lowercase form.
##  * Use comma-separated hostname:port values.
##  * IP addresses are okay, but hostnames are never resolved.
##  * Suffixes match without `*` (e.g. foo.com is the wildcard for *.foo.com).
##  * IP ranges in CIDR format (e.g.: 10/6) are not supported.
##
##  Reference:
##  https://about.gitlab.com/blog/2021/01/27/we-need-to-talk-no-proxy/
##
function shell_noproxy_from_macos_bypass ()
{
    typeset -a exception_list=()

    (( ${+commands[scutil]} )) && exception_list=( $(scutil --proxy | awk '/ExceptionsList : <array> {/,/}/  {if (/^[[:space:]]+[[:digit:]]+ : /) { $1="" ; $2="" ; print $3 }}') )
    # TODO: Support `gsettings` output, which looks like: ['localhost', '127.0.0.0/8', '::1', '*.local']

    # If the exception list is empty, bail.
    (( ${#exception_list} )) || return

    # `zsh` Parameter Expansion Explanation
    # -------------------------------------
    # Start with the array parameter name (`exception_list`), and work outward.
    # Operator  #\*.   : Strip the first instance of '.*' from all elements
    #                    (no_proxy disallows this form of wildcarding).
    # Operator  :#*/*  : Remove any element containing a slash
    #                    (`no_proxy` doesn't support CIDR IP ranges).
    # Flag      j','   : Join array elements into a single word using a comma.
    echo ${(j',')${exception_list#\*.}:#*/*}
}


##
##  Set or unset all proxy parameters for the current environment.
##  With no action, print all proxy parameters.
##
##  If no URL is specified with the `set` action, the value of the
##  `$USER_PROXY_URL` parameter will be evaluated.
##
function user_proxy ()  # [set | unset] [user_proxy_url]
{
    typeset -a actions=( 'set' 'unset' )
    typeset action="${1}"

    typeset -a all_param_names=( ${PROXY_ENV_PARAMETER_NAMES} ${NOPROXY_ENV_PARAMETER_NAMES} )

    [[ -z "${action}" ]] &&
    {
        typeset -i max_name_length=${${(ONn)all_param_names%%*}[1]}
        for param_name ( ${all_param_names} ) { echo "${(r:$max_name_length:)param_name:u} ${(r:$max_name_length:)param_name:l} '${(P)param_name}'" }
        return
    }

    (( ${actions[(Ie)$action]} )) || fail "Specified action must be one of: (${(j', ')actions})." 10

    # Always unset all values.  No need to check for that action.
    echo_debug 'Un-setting all proxy-related environment parameters.'
    for param_name ( ${all_param_names:u} ${all_param_names:l} ) { unset "${param_name}" }

    [[ "${action}" == "set" ]] || return

    typeset proxy_url="${2}"
    [[ -n "${proxy_url}" ]] || proxy_url="${USER_PROXY_URL}"
    [[ -n "${proxy_url}" ]] || fail 'No proxy URL was provided.  $USER_PROXY_URL is also unset or empty.' 20

    echo_debug "Setting proxy URL for current environment to '${proxy_url}'."
    for param ( ${PROXY_ENV_PARAMETER_NAMES:u} ${PROXY_ENV_PARAMETER_NAMES:l} )
    {
        typeset -gx "${param}"="${proxy_url}"
    }

    typeset noproxy_value="${(j:,:)USER_PROXY_DIRECT}"
    [[ -n "${noproxy_value}" ]] || noproxy_value="$( shell_noproxy_from_macos_bypass )"
    [[ -n "${noproxy_value}" ]] ||
    {
        echo_log "The 'NO_PROXY' environment variable could not be set automatically for this shell session." WARN
        return 0
    }

    echo_debug "Setting no-proxy bypass for current environment to '${noproxy_value}'."
    for noproxy_param ( ${NOPROXY_ENV_PARAMETER_NAMES:u} ${NOPROXY_ENV_PARAMETER_NAMES:l} )
    {
        typeset -gx "${noproxy_param}"="${noproxy_value}"
    }
}

