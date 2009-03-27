#!/bin/sh

# You need to set NIGHTLY_HOST and NIGHTLY_USER in environment, and have your 
# public key in the authorized_keys file on the nightly server.

# Set our working directory to be the parent of this script, in case we're run
# from somewhere else.
PARENT=$(dirname $0)
cd ${PARENT:-.}

ADIUM_RELEASE_NAME=`head -n 1 build/latest | tail -n 1`
scp build/latest build/${ADIUM_RELEASE_NAME}.tgz ${NIGHTLY_USER}@${NIGHTLY_HOST}