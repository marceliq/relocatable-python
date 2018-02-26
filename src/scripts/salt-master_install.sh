#!/usr/bin/env bash
#set -x

PYTHON_PREFIX="/opt/centman/salt/dist"
SALT_PREFIX="/opt/centman/salt"

# Nastavi korekne utility dle platformy
AWK=awk
GREP=grep
EGREP=egrep
TAR=tar
CURL=curl

case "`uname`" in
    CYGWIN*)
        cygwin=true
        ;;

    Darwin*)
        darwin=true
        ;;

    Linux)
        linux=true
        PATH=${PYTHON_PREFIX}/bin:$PATH
        ;;

    SunOS*)
        solaris=true
        AWK=nawk
        GREP=/usr/sfw/bin/ggrep
        TAR=/usr/sfw/bin/gtar
        CURL=/opt/csw/bin/curl
        ;;

    *)
        other=true
        ;;
esac

# Install pip
if [ ! -f "${PYTHON_PREFIX}/bin/pip" ]; then
    ${CURL} -L -J https://bootstrap.pypa.io/get-pip.py | ${PYTHON_PREFIX}/bin/python2.7 || exit 1
fi

# Lookup for latest Salt version
LATEST=`${PYTHON_PREFIX}/bin/pip search salt |${EGREP} '^salt\ \([0-9][0-9][0-9][0-9]' |${AWK} -F '[()]' '{print $2}'` || exit 1

# Zalozi docasny adresar
TMPDIR=${SALT_PREFIX}/tmp
if [ ! -d "${TMPDIR}" ]; then
    mkdir -p ${TMPDIR} || exit 1
fi

# stahnout zdrojaky saltu kvuli requirements
cd ${TMPDIR} || exit 1
PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip download --no-deps --no-binary :all: salt==${LATEST} || exit 1

# vybalit jenom requirements
${TAR} --extract --file=salt-${LATEST}.tar.gz salt-${LATEST}/requirements || exit 1

# nainstalovat requirementy a uklidit zdrojaky saltu
if [ "$solaris" = true ]; then
    PATH=/usr/sfw/bin:$PATH PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
    --no-cache-dir \
    -r ${TMPDIR}/salt-${LATEST}/requirements/base.txt \
    -r ${TMPDIR}/salt-${LATEST}/requirements/zeromq.txt \
    glances elasticsearch redis progressbar|| exit 1
else
    PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
    --no-cache-dir --global-option=build_ext --global-option="-I${PYTHON_PREFIX}/include/" --global-option="--rpath=${PYTHON_PREFIX}/lib64" M2Crypto python-ldap || exit 1
    PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
    --no-cache-dir \
    -r ${TMPDIR}/salt-${LATEST}/requirements/base.txt \
    -r ${TMPDIR}/salt-${LATEST}/requirements/zeromq.txt \
    pygit2 cherrypy python-gnupg glances elasticsearch redis progressbar flask pysmb pysmbclient kafka-python certifi jira bpython progressbar Saltscaffold \
    fabric pepa salt-pepper reclass || exit 1
fi

# vybalit minion conf do rootu saltu
cd ${SALT_PREFIX} || exit 1
${TAR} xzf ${TMPDIR}/salt-${LATEST}.tar.gz salt-${LATEST}/conf --strip-components=1
rm -rf ${TMPDIR} || exit 1

# instalace saltu pres pip
PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
--global-option="--salt-root-dir=${SALT_PREFIX}" \
--global-option="--salt-config-dir=${SALT_PREFIX}/conf" \
--install-option="--install-scripts=${SALT_PREFIX}/bin" \
--no-compile salt==${LATEST} || exit 1

# opatchovani Saltu pro Solaris
if [ "$solaris" = true ]; then
    patch -i ${SALT_PREFIX}/src/patches/salt-${LATEST}-solaris-rsax931.patch ${PYTHON_PREFIX}/lib64/python2.7/site-packages/salt/utils/rsax931.py || exit 1
fi

# prejmenovani minion conf adresare
mv ${SALT_PREFIX}/conf ${SALT_PREFIX}/conf-${LATEST}

# python cleanup
rm -rf \
${PYTHON_PREFIX}/lib64/python2.7/bsddb/test \
${PYTHON_PREFIX}/lib64/python2.7/ctypes/test \
${PYTHON_PREFIX}/lib64/python2.7/distutils/tests \
${PYTHON_PREFIX}/lib64/python2.7/email/test \
${PYTHON_PREFIX}/lib64/python2.7/idlelib/idle_test \
${PYTHON_PREFIX}/lib64/python2.7/json/tests \
${PYTHON_PREFIX}/lib64/python2.7/lib-tk/test \
${PYTHON_PREFIX}/lib64/python2.7/lib2to3/tests \
${PYTHON_PREFIX}/lib64/python2.7/sqlite3/test \
${PYTHON_PREFIX}/lib64/python2.7/test || exit 1

for f in `find ${PYTHON_PREFIX} -type f | egrep 'pyc$|pyo$'`; do rm -f ${f}; done

if [ "$solaris" = true ]; then
    cd ${SALT_PREFIX}
    tar -cf - bin/salt* bin/spm conf dist |gzip -c >${SALT_PREFIX}/salt-master-${LATEST}-`uname -s`-`uname -r`-`uname -p`.tar.gz
else
    cd ${SALT_PREFIX}
    tar -cf - bin/salt* bin/spm conf-${LATEST} dist |gzip -c >${SALT_PREFIX}/salt-master-${LATEST}-`uname -s`-`uname -p`.tar.gz
fi
