##
##  ZPROFILE EXTENSION:
##  Docker
##



################################################################################
##  DOCKER DESKTOP CLI TOOLS
##

typeset docker_desktop_app_root="/Applications/Docker.app/Contents/Resources"
[[ -d "${docker_desktop_app_root}" ]] || return 0


####
##  AMEND `path` WITH PATH TO EXECUTABLES IN Docker Desktop BUNDLE.
##

path=(
    "${docker_desktop_app_root}/bin"
    ${path}
)


