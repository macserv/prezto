#
#  Enable network proxies.
#
function proxies_on()
{
    export HTTP_PROXY="${http_proxy_value}"
    export HTTPS_PROXY="${https_proxy_value}"
    export ALL_PROXY="${all_proxy_value}"
    export NO_PROXY="${no_proxy_value}"

    export http_proxy="${HTTP_PROXY}"
    export https_proxy="${HTTPS_PROXY}"
    export all_proxy="${ALL_PROXY}"
    export no_proxy="${NO_PROXY}"
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
