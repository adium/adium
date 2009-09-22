#!/bin/bash -eu

ROOTDIR=$(pwd)
if ! expr "$ROOTDIR" : '.*/Dependencies$' &> /dev/null; then
	error "Please run this script from the Dependencies directory."
	exit 1
fi

ADIUM="`dirname $0`/.."

cp -R "$ROOTDIR"/Frameworks/*.subproj/*.framework "$ADIUM/Frameworks/"

pushd "$ADIUM/build" > /dev/null 2>&1
	rm -rf */AdiumLibpurple.framework 
	rm -rf */*/Adium.app/Contents/Frameworks/lib*
popd > /dev/null 2>&1

echo "Done - now build Adium"
