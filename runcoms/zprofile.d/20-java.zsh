##
##  ZPROFILE EXTENSION:
##  java
##

##  Dynamically set JAVA_HOME to the currently selected JVM.
##  Fail silently if it's not present.
##  Note: This fails unless Java is installed in /Library.
##  typeset -gx JAVA_HOME="$(/usr/libexec/java_home &>/dev/null ; trap)"

##  Use Homebrew-installed OpenJDK
typeset -gx JAVA_HOME="${HOMEBREW_PREFIX}/opt/openjdk/"

path=(
    ${JAVA_HOME}/bin
    $path
)
