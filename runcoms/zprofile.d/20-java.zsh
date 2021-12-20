#
# ZPROFILE EXTENSION:
# java
#


# Dynamically set JAVA_HOME to the currently selected JVM.
# Fail silently if it's not present.
export JAVA_HOME="$(/usr/libexec/java_home > /dev/null 2>&1; trap)"
