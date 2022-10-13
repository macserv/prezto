#
# ZSHRC EXTENSION:
# Functions: Proxy Management
#


#
#
#
function noproxy_from_system_bypass
{
    typeset -a exception_list=( $(scutil --proxy | awk '/ExceptionsList : <array> {/,/}/  {if (/^[[:space:]]+[[:digit:]]+ : /) { $1="" ; $2="" ; print $3 }}') )

    # `zsh` Parameter Expansion
    # Start with the array, `exception_list`, and work outward...
    # Operator  #\*.   : Strip the first instance of '.*' from all elements (no_proxy disallows this form of wildcarding).
    # Operator  :#*/*  : Remove any element containing a slash (no_proxy doesn't support CIDR IP ranges).
    # Flag      j','   : Join array elements into a single word using a comma.
    echo ${(j',')${exception_list#\*.}:#*/*}
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
