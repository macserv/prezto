##
##  ZPROFILE EXTENSION:
##  GenAI/LLM Tooling
##


# Added by LM Studio CLI (lms)
typeset lms_path="${HOME}/.lmstudio/bin"
[[ -d "${lms_path}" ]] || return 0


path=(
    "${lms_path}"
    ${path}
)
