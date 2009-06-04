#!/bin/bash

# You need to set NIGHTLY_HOST and NIGHTLY_USER in environment, and have your 
# public key in the authorized_keys file on the nightly server.

# Set our working directory to be the parent of this script, in case we're run
# from somewhere else.
PARENT=$(dirname $0)
cd ${PARENT:-.}

ADIUM_RELEASE_NAME=`head -n 1 build/latest.info | tail -n 1`
scp build/latest.info build/${ADIUM_RELEASE_NAME}.dmg.md5 build/${ADIUM_RELEASE_NAME}.dmg ${NIGHTLY_USER}@${NIGHTLY_HOST}:
ssh ${NIGHTLY_USER}@${NIGHTLY_HOST} chmod go+r ${ADIUM_RELEASE_NAME}.dmg latest.info ${ADIUM_RELEASE_NAME}.dmg.md5

