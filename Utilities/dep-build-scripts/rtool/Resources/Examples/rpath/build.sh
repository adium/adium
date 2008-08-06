#!/bin/sh

script_path=`dirname "${0}"`
cd "${script_path}"

echo "-> building libutil.dylib --"
gcc -dynamiclib util.c -install_name "@executable_path/libutil.dylib" -o libutil.dylib -framework CoreFoundation

echo "-> building libbar.dylib --"
gcc -dynamiclib bar.c -install_name "@executable_path/libbar.dylib" -o libbar.dylib -L. -lutil

echo "-> building libfoo.dylib --"
gcc -dynamiclib foo.c -install_name "@executable_path/libfoo.dylib" -o libfoo.dylib -L. -lbar -lutil

echo "-> building main --"
gcc main.c -o main -L. -lfoo -lbar -lutil

echo "-> testing binaries --"

bins="main libfoo.dylib libbar.dylib libutil.dylib"

for bin in $bins; do
	
	echo "## from" $(dirname $bin) "--"
	echo "###" $(basename $bin) 
	otool -LX $bin | awk '{print $1}'
	echo ""
	
done

echo "-> executing main from . --"

./main

echo "-> executing main from $(pwd) --"

$(pwd)/main

rm -f main libfoo.dylib libbar.dylib libutil.dylib