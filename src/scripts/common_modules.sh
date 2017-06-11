#!/usr/bin/env bash

PYTHON_PREFIX="/opt/salt/common/python27"

# Install pip
/opt/csw/bin/curl -L -J https://bootstrap.pypa.io/get-pip.py | ${PYTHON_PREFIX}/bin/python2.7

# Install "system wide" python modules pyzmq, psutil, virtualenv, glances
PATH=/usr/sfw/bin:$PATH PKG_CONFIG_PATH="${PYTHON_PREFIX}/lib64/pkgconfig:${PYTHON_PREFIX}/lib/pkgconfig" ${PYTHON_PREFIX}/bin/pip install --no-cache-dir pyzmq psutil virtualenv glances

