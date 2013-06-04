#!/bin/sh

script_path=`dirname "${0}"`
cd "${script_path}"

mkdir -p build
ln -sf ../../../rtool rtool_sub

FRAMEWORK_ROOT=@executable_path/../Frameworks
FRAMEWORK_NAME=xmlLib
FRAMEWORK_VERSION=A

BUILDDIR=build

LIBRARY="/usr/lib/libxml2.2.dylib"
BINARIES="/usr/bin/xmlcatalog"
HEADERS="/usr/include/libxml2/libxml" # a directory to copy or a list of headers
MANUALS="/usr/share/man/man1/xmlcatalog.1"

sh ./rtool_sub \
--framework_root=${FRAMEWORK_ROOT} \
--framework_name=${FRAMEWORK_NAME} \
--framework_version=${FRAMEWORK_VERSION} \
--library=${LIBRARY} \
--builddir=${BUILDDIR} \
--binaries="${BINARIES}" \
--headers="${HEADERS}" \
--manuals="${MANUALS}"
# --headers_no_root

echo "-- done --"
rm -f rtool_sub