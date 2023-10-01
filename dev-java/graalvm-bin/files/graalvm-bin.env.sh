VERSION="GraalVM JDK ${PV}"
JAVA_HOME="${EPREFIX}/opt/${P}"
JDK_HOME="${EPREFIX}/opt/${P}"
JAVAC="\${JAVA_HOME}/bin/javac"
PATH="\${JAVA_HOME}/bin"
ROOTPATH="\${JAVA_HOME}/bin"
LDPATH="\${JAVA_HOME}/lib/:\${JAVA_HOME}/lib/server/"
MANPATH=""
PROVIDES_TYPE="JDK JRE"
PROVIDES_VERSION="${SLOT}"
BOOTCLASSPATH=""
GENERATION="2"
ENV_VARS="JAVA_HOME JDK_HOME JAVAC PATH ROOTPATH LDPATH MANPATH"