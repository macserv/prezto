#
# ZSHRC EXTENSION:
# Functions: Proxy Management
#


#
#
#
function noproxy_from_system_bypass
{
    typeset -a exception_list=(  $(scutil --proxy | awk '/ExceptionsList : <array> {/,/}/  {if (/^[[:space:]]+[[:digit:]]+ : /) { $1="" ; $2="" ; print $3 }}') )

    # Join the list elements, with commas, and filter out any value containing
    # a slash because they're probably CIDR IP ranges, which only work with Go.
    echo "${(@j',')exception_list:#*/*}"
}


#
#  Enable network proxies.
#
function proxies_on()
{
    typeset -gx HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY
    typeset -gx http_proxy https_proxy all_proxy no_proxy
    
    HTTP_PROXY="${http_proxy_value}"
    HTTPS_PROXY="${https_proxy_value}"
    ALL_PROXY="${all_proxy_value}"
    NO_PROXY="$( noproxy_from_system_bypass )"
    
    http_proxy="${HTTP_PROXY}"
    https_proxy="${HTTPS_PROXY}"
    all_proxy="${ALL_PROXY}"
    no_proxy="$( noproxy_from_system_bypass )"
}


#
#  Disable network proxies.
#
function proxies_off()
{
    unset HTTP_PROXY
    unset HTTPS_PROXY
    unset ALL_PROXY
    unset NO_PROXY

    unset http_proxy
    unset https_proxy
    unset all_proxy
    unset no_proxy
}
