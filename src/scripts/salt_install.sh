#!/usr/bin/env bash
PYTHON_PREFIX="/opt/salt/dist"
SALT_PREFIX="/opt/salt"

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
if $solaris; then
    PATH=/usr/sfw/bin:$PATH PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
    --no-cache-dir \
    -r ${TMPDIR}/salt-${LATEST}/requirements/base.txt \
    -r ${TMPDIR}/salt-${LATEST}/requirements/zeromq.txt \
    glances elasticsearch redis progressbar|| exit 1
else
    PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
    --no-cache-dir \
    -r ${TMPDIR}/salt-${LATEST}/requirements/base.txt \
    -r ${TMPDIR}/salt-${LATEST}/requirements/zeromq.txt || exit 1
fi

# vybalit minion conf do rootu saltu
cd ${SALT_PREFIX} || exit 1
${TAR} xzf ${TMPDIR}/salt-${LATEST}.tar.gz salt-${LATEST}/conf/minion --strip-components=1
rm -rf ${TMPDIR} || exit 1

# prejmenovani minion conf souboru
mv ${SALT_PREFIX}/conf/minion ${SALT_PREFIX}/conf/minion-${LATEST}

# instalace saltu pres pip
PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install \
--global-option="--salt-root-dir=${SALT_PREFIX}" \
--global-option="--salt-config-dir=${SALT_PREFIX}/conf" \
--install-option="--install-scripts=${SALT_PREFIX}/bin" \
--no-compile salt==${LATEST} || exit 1

# opatchovani Saltu pro Solaris
if $solaris; then
    patch -i ${SALT_PREFIX}/src/patches/salt-${LATEST}-solaris-rsax931.patch ${PYTHON_PREFIX}/lib64/python2.7/site-packages/salt/utils/rsax931.py || exit 1
fi

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

for f in `find ${PYTHON_PREFIX} -type f | grep 'pyc$'`; do rm -f ${f}; done

if $solaris; then
    cd ${SALT_PREFIX}
    tar -cvf - bin/salt* bin/spm conf dist |gzip -c >/opt/salt/salt-minion-${LATEST}-`uname -s`-`uname -r`-`uname -p`.tar.gz
fi
