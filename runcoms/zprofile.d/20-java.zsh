##
##  ZPROFILE EXTENSION:
##  java
##


##  Use Homebrew-installed OpenJDK
typeset java_home="${HOMEBREW_PREFIX}/opt/openjdk"
[[ -x "${java_home}/bin/java" ]] || return 0

typeset -gx JAVA_HOME="${java_home}"

path=(
    "${JAVA_HOME}/bin"
    $path
)
