#!/bin/sh 
ADIUM="`dirname $0`/../.."

cp -r "`dirname $0`"/build/Frameworks/*.subproj/*.framework "$ADIUM/Frameworks/"

pushd "$ADIUM/build" > /dev/null 2>&1
	rm -rf */AdiumLibpurple.framework 
	rm -rf */*/Adium.app/Contents/Frameworks/lib*
popd > /dev/null 2>&1

echo "Done - now build Adium"
