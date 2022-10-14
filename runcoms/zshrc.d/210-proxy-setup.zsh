#
# ZSHRC EXTENSION:
# Functions: Proxy Setup
#


typeset -gx http_proxy_value="${proxy_url}"
typeset -gx https_proxy_value="${proxy_url}"
typeset -gx all_proxy_value="${proxy_url}"
typeset -gx no_proxy_value=$( noproxy_from_system_bypass )

typeset -gx HTTP_PROXY="${http_proxy_value}"
typeset -gx HTTPS_PROXY="${https_proxy_value}"
typeset -gx ALL_PROXY="${all_proxy_value}"
typeset -gx NO_PROXY="${no_proxy_value}"

typeset -gx http_proxy="${http_proxy_value}"
typeset -gx https_proxy="${https_proxy_value}"
typeset -gx all_proxy="${all_proxy_value}"
typeset -gx no_proxy="${no_proxy_value}"

