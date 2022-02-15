#
# ZSHRC EXTENSION:
# Functions: Proxy Management
#


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
    NO_PROXY="${no_proxy_value}"
    
    http_proxy="${HTTP_PROXY}"
    https_proxy="${HTTPS_PROXY}"
    all_proxy="${ALL_PROXY}"
    no_proxy="${NO_PROXY}"
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
