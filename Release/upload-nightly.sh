#!/bin/bash

# You need to set NIGHTLY_HOST, NIGHTLY_USER, NIGHTLY_REPO, and NIGHTLY_BRANCH in environment, and have your 
# public key in the authorized_keys file on the nightly server.

# Set our working directory to be the parent of this script, in case we're run
# from somewhere else.
PARENT=$(dirname $0)
cd ${PARENT:-.}

ADIUM_RELEASE_NAME=`head -n 1 build/latest.info | tail -n 1`

# Create ${NIGHTLY_REPO}-${NIGHTLY_BRANCH} directory, if it doesn't exist
ssh ${NIGHTLY_USER}@${NIGHTLY_HOST} "ls -d ${NIGHTLY_REPO}-${NIGHTLY_BRANCH} || mkdir ${NIGHTLY_REPO}-${NIGHTLY_BRANCH}"

scp build/latestDelta.info build/latest.info build/${ADIUM_RELEASE_NAME}.dmg.md5 build/${ADIUM_RELEASE_NAME}.dmg ${NIGHTLY_USER}@${NIGHTLY_HOST}:${NIGHTLY_REPO}-${NIGHTLY_BRANCH}

for file in build/deltas/*.delta; do
        scp $file ${NIGHTLY_USER}@${NIGHTLY_HOST}:${NIGHTLY_REPO}-${NIGHTLY_BRANCH}
done

ssh ${NIGHTLY_USER}@${NIGHTLY_HOST} chmod go+r ${NIGHTLY_REPO}-${NIGHTLY_BRANCH}/${ADIUM_RELEASE_NAME}.dmg ${NIGHTLY_REPO}-${NIGHTLY_BRANCH}/latest.info ${NIGHTLY_REPO}-${NIGHTLY_BRANCH}/latestDelta.info ${NIGHTLY_REPO}-${NIGHTLY_BRANCH}/${ADIUM_RELEASE_NAME}.dmg.md5

ssh ${NIGHTLY_USER}@${NIGHTLY_HOST} for file in ${NIGHTLY_REPO}-${NIGHTLY_BRANCH}/*.delta; do chmod go+r $file done
