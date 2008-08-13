#!/usr/bin/env zsh -f

export ACTION=build
export ONLY_ACTIVE_ARCH=YES
export DEVELOPER_DIR="${DEVELOPER_DIR:-/Developer}"
export DEVELOPER_LIBRARY_DIR="${DEVELOPER_LIBRARY_DIR:-/Developer/Library}"
export DEVELOPER_TOOLS_DIR="${DEVELOPER_TOOLS_DIR:-/Developer/Tools}"
export CONFIGURATION="${CONFIGURATION:-Debug}"
export BUILT_PRODUCTS_DIR="$PWD/build/$CONFIGURATION"
export PRODUCT_NAME="$(basename $1)"
export WRAPPER_EXTENSION="${WRAPPER_EXTENSION:-octest}"
export FULL_PRODUCT_NAME="$PRODUCT_NAME.$WRAPPER_EXTENSION"
export TEST_AFTER_BUILD=YES

if [ "x$PRODUCT_NAME" = "x" ]; then
	echo "Usage: $0 PRODUCT_NAME" > /dev/stderr
	echo "PRODUCT_NAME is the name of the unit test bundle, not including the filename extension." > /dev/stderr
	echo "Environment variables you may want to override:" CONFIGURATION WRAPPER_EXTENSION DEVELOPER_DIR DEVELOPER_LIBRARY_DIR DEVELOPER_TOOLS_DIR BUILT_PRODUCTS_DIR > /dev/stderr
	echo '(See RunUnitTests(1) for what those variables do.)' > /dev/stderr
fi

"$DEVELOPER_TOOLS_DIR/RunUnitTests"
