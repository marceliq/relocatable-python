#!/usr/bin/env bash

PYTHON_PREFIX="/opt/salt/common/python27"
SALT_PREFIX="/opt/salt"

# Install pip
#/opt/csw/bin/curl -L -J https://bootstrap.pypa.io/get-pip.py | ${PYTHON_PREFIX}/bin/python2.7

# Install "system wide" python modules pyzmq, psutil, virtualenv, glances
#PATH=/usr/sfw/bin:$PATH PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install --no-cache-dir pyzmq psutil virtualenv glances

# Lookup for latest Salt version
LATEST=`${PYTHON_PREFIX}/bin/pip search salt |egrep '^salt\ \([0-9][0-9][0-9][0-9]' |nawk -F '[()]' '{print $2}'`

# Create new virtual environment
${PYTHON_PREFIX}/bin/virtualenv --system-site-packages ${SALT_PREFIX}/${LATEST}

# Activate new virtual environment
source ${SALT_PREFIX}/${LATEST}/bin/activate

# Install Salt dependencies to virtual environment
PATH=/usr/sfw/bin:$PATH pip install --no-cache-dir Jinja2 PyYAML backports-abc certifi futures msgpack-python pycrypto singledispatch tornado requests

# Install Salt
pip install --global-option="--salt-root-dir=/opt/salt" --global-option="--salt-config-dir=/opt/salt/etc/conf" --no-cache-dir salt==${LATEST}
deactivate

# Patch rsax931.py
patch -i ${SALT_PREFIX}/rsax931.patch ${LATEST}/lib/python2.7/site-packages/salt/utils/rsax931.py || exit 1

# Symlink latest to current
rm ${SALT_PREFIX}/current
ln -sf ${SALT_PREFIX}/${LATEST} ${SALT_PREFIX}/current
