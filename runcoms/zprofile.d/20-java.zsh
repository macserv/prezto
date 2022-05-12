#
# ZPROFILE EXTENSION:
# java
#

# Use Homebrew-installed OpenJDK
path=(
    ${HOMEBREW_PREFIX}/opt/openjdk/bin
    $path
)

# Dynamically set JAVA_HOME to the currently selected JVM.
# Fail silently if it's not present.
# typeset -gx JAVA_HOME="$(/usr/libexec/java_home > /dev/null 2>&1; trap)"
typeset -gx JAVA_HOME="$(/usr/libexec/java_home > /dev/null 2>&1; trap)"
