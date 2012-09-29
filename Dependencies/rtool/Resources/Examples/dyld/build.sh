#!/bin/sh

script_path=`dirname "${0}"`
cd "${script_path}"

echo "-> building libfoo.dylib --"
gcc -dynamiclib foo.c -install_name "libfoo.dylib" -o libfoo.dylib

echo "-> building bar.dylib --"
gcc -dynamiclib bar.c -install_name "@executable_path/libbar.dylib" -o libbar.dylib

echo "-> building main --"
gcc main.c -o main -L. -lfoo -lbar

echo "-> testing binary:: Library not loaded: libfoo.dylib --"

(cd .. && ./dyld/main)

echo ""

echo "-> exporting dyld dir in DYLD_LIBRARY_PATH"

export DYLD_LIBRARY_PATH="dyld:$DYLD_LIBRARY_PATH"

echo "-> testing binary:: loaded libfoo.dylib--"

(cd .. && ./dyld/main)

rm -f main libfoo.dylib libbar.dylib