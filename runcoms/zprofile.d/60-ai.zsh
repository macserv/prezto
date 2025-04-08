##
##  ZPROFILE EXTENSION:
##  GenAI/LLM Tooling
##



################################################################################
##  LMStudio CLI SUPPORT: `lms`
##

typeset lms_path="${HOME}/.lmstudio/bin"
[[ -d "${lms_path}" ]] || return 0


####
##  AMEND `path` WITH LMStudio EXECUTABLE PATH.
##

path=(
    "${lms_path}"
    ${path}
)


