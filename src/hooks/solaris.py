import os
import logging
log = logging.getLogger('hook')

def mklibdir(options, buildout, environment):
    libdir = options['prefix'] + '/lib'
    log.info('Creating lib directory: %s' % libdir)
    os.makedirs(libdir)
