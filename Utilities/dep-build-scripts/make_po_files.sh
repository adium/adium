#!/bin/sh

source common.sh
setupDirStructure
cd "$BUILDDIR"

pushd $PIDGIN_SOURCE

	for patch in "$PATCHDIR/libpurple-restrict-potfiles-to-libpurple.diff" ; do
    	echo "Applying $patch"
		patch --forward -p0 < $patch || true
	done

popd

pushd $BUILDDIR/libpurple-i386/po
	#make update-po && make all && make install
	make all && make install
popd

pushd $BUILDDIR/root-i386/share/locale
	mkdir $BUILDDIR/Frameworks/libpurple.subproj/libpurple.framework/Resources || true
	cp -v -r * $BUILDDIR/Frameworks/libpurple.subproj/libpurple.framework/Resources
popd

pushd $BUILDDIR/Frameworks/libpurple.subproj/libpurple.framework/Resources
	find . \( -name gettext-runtime.mo -or -name gettext-tools.mo -or -name glib20.mo \) -type f -delete
popd

echo "Done - now run ./copy_frameworks.sh"
