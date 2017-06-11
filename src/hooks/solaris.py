import os
import logging
log = logging.getLogger('hook')

def mklibdir(options, buildout, environment):
    libdir = options['prefix'] + '/lib'
    log.info('Creating lib directory: %s' % libdir)
    os.makedirs(libdir)

def common_modules(options, buildout, version):
    from subprocess import Popen
    from os import name
    if name == 'nt':
        return
    process = Popen(['curl'])
    process.wait()

