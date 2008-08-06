#!/bin/sh

mkdir -p X.app/Contents/Frameworks
mkdir -p X.app/Contents/MacOS

echo "-> building libB.dylib --"
gcc -dynamiclib B.c -install_name "@executable_path/../Frameworks/libB.dylib" -o libB.dylib -framework CoreFoundation

echo "-> building libA.dylib --"
gcc -dynamiclib A.c -install_name "@executable_path/../Frameworks/libA.dylib" -o libA.dylib ./libB.dylib

echo "-> building X --"
gcc X.c -o X libA.dylib libB.dylib

mv *.dylib X.app/Contents/Frameworks/

echo "-> executing MacOS/X --"
mv X X.app/Contents/MacOS/X

./X.app/Contents/MacOS/X

rm -Rf ./X.app