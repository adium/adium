#!/bin/bash -eu

ROOTDIR=$(pwd)
if ! expr "$ROOTDIR" : '.*/Dependencies$' &> /dev/null; then
	error "Please run this script from the Dependencies directory."
	exit 1
fi

ADIUM="`dirname $0`/.."

# Don't allow any out-of-date plugins to hang around and be subsequently laoded
rm -rf "$ADIUM/Frameworks/libgstreamer.framework/PlugIns"

cp -Rf "$ROOTDIR"/Frameworks/*.subproj/*.framework "$ADIUM/Frameworks/" || TRUE

# These libgst plugins cause problems in gst_init if present; we shouldn't
# be building them at all.
rm "$ADIUM/Frameworks/libgstreamer.framework/PlugIns/libgstwavenc.so"
rm "$ADIUM/Frameworks/libgstreamer.framework/PlugIns/libgstwavparse.so"
rm "$ADIUM/Frameworks/libgstreamer.framework/PlugIns/libgsty4menc.so"

echo "Cleaning the Adium built products"

pushd "$ADIUM/build" > /dev/null 2>&1
	rm -rf */AdiumLibpurple.framework 
	rm -rf */*/Adium.app/Contents/Frameworks/lib*
popd > /dev/null 2>&1

echo "Done - now build Adium"
