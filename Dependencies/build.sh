#!/bin/bash -eu

##
# status <string>
#
status() {
	echo -e "\033[36m$1\033[0m"
}

##
# error <string>
#
error() {
	echo -e "\033[91mError: $1\033[0m" 1>&2
}

##
# warning <string>
#
warning() {
	echo -e "\033[33mWarning: $1\033[0m" 1>&2
}

##
# asserttools <tool> ...
#
# Checks to make sure the listed tools are installed, and errors if one is not
# found.
asserttools() {
	missing=false
	for tool in ${@:1}; do
		if ! which $tool &> /dev/null; then
			error "Missing required tool $tool."
			missing=true
		fi
	done
	
	if $missing; then exit 1; fi
}

##
# needsconfigure <opts>
# 
# Checks if the current directory has a config.status file, or if the options
# passed include --configure
needsconfigure() {
	needsconfig=true
	if [ -f config.status ]; then needsconfig=false; fi
	
	for opt in ${@:1}; do
		if [ "$opt" = "--configure" ]; then
			needsconfig=true
			break
		fi
	done 
	
	"$needsconfig"
}

##
# prereq <package> <URL>
#
# Downloads the source code to the package if it is not already found in the 
# source directory.
#
prereq() {
	if [ -d "$ROOTDIR/source/$1" ]; then return 0; fi
	quiet pushd "$ROOTDIR/source"
	
	# Work out the file extension from the name
	ext=""
	for zxt in ".tar.gz" ".tgz" ".tar.bz2" ".tbz", ".tar", ".zip"; do
		if expr "$2" : '.*'${zxt//./\.}'$' > /dev/null; then
			ext=$zxt
			break
		fi
	done
	
	if [ "$ext" = "" ]; then
		error "Couldn't autodetect file type of $0"
		exit 1
	fi
	
	# Download the package
	status "Downloading source for package $1"
	curl -Lfo "$1$ext" "$2"
	
	# Extract the source to a fixed directory name
	status "Extracting source for package $1"
	case "$ext" in
		\.tar\.gz|\.tgz)
			tarflags=z
			;;
		\.tar\.bz2|\.tbz)
			tarflags=j
			;;
		\.tar)
			tarflags=
			;;
		\.zip)
			# Zip is a pain in the ass. We have to decide whether to make a
			# directory and extract into it, or otherwise extract the archive
			# and then rename the parent directory.
			error "Too lazy to unzip package $1"
			exit 1
			;;
	esac
	
	# Count the number of parent directories there are
	IFS="/" read -a firstfile < <(tar t${tarflags}f "$1$ext" | head -n 1)
	levels=(${#firstfile[@]} - 1)
	
	# Extract to the source directory
	quiet mkdir "$1"
	tar x${tarflags}f "$1$ext" --strip-components $levels -C "$1"
	
	# Clean up and resume previous operation
	if [ -f "$1$ext" ]; then rm -f "$1$ext"; fi
	quiet popd
}

##
# quiet <cmd ...>
#
# Tries to execute a command silently, and catches the error if it fails.
#
quiet() {
	${@:1} &> /dev/null || true
}

##
# fwdpatch <patchfile> <opts>
#
# Patches files without modifying their access or modified times. We do this so
# that we don't upset Make when we patch and unpatch on the fly.
#
fwdpatch() {
	# Figure out which direction we're going in
	mode="Applying"
	for opt in ${@:2}; do
		if [ "$opt" = "-R" ]; then
			mode="Reversing"
			break
		fi
	done
	
	# Get the list of files that will be changed
	patchfiles=( )
	while read line
	do
		file=$(expr "$line" : '^patching file \(.*\)$')
		if [ "$file" != "" ]; then
			patchfiles[${#patchfiles[*]}]="$file"
		fi
	done < <(patch -fi "$1" --dry-run ${@:2})
	
	# Record the old times
	access=( )
	modify=( )
	for file in $patchfiles; do
		access[${#access[*]}]=$(date -r $(stat -f "%a" "$file") +%Y%m%d%H%M.%S)
		modify[${#modify[*]}]=$(date -r $(stat -f "%m" "$file") +%Y%m%d%H%M.%S)
	done
	
	# Go ahead and apply the patch
	if [ ${#patchfiles[@]} -eq 1 ]; then
		status "$mode patch $(basename \"$1\") to 1 file"
	else
		status "$mode patch $(basename \"$1\") to ${#patchfiles[@]} files"
	fi
	patch -fi "$1" ${@:2}
	
	# Go back and reset the times on all the files
	index=0
	while [ "$index" -lt ${#patchfiles[@]} ]; do
		touch -at ${access[$index]} ${patchfiles[$index]}
		touch -mt ${modify[$index]} ${patchfiles[$index]}
		index+=1
	done
}

##
# revpatch <patchfile> <opts>
#
# Reverses a patch. You should always do this when finished building, so the
# developer always works on the unpatched code.
revpatch() {
	fwdpatch $@ -R
}

##
# pkg-config
#
# We only need a native pkg-config, so no worries about making it a Universal
# Binary.
#
build_pkgconfig() {
	prereq "pkg-config" \
		"http://pkgconfig.freedesktop.org/releases/pkg-config-0.22.tar.gz"
	
	quiet pushd "$ROOTDIR/source/pkg-config"
	
	if needsconfigure $@; then
		status "Configuring pkg-config"
		./configure --prefix="$ROOTDIR/build"
	fi
	
	status "Building and installing pkg-config"
	make
	make install
	
	quiet popd
}

##
# gettext
#
build_gettext() {
	prereq "gettext" \
		"http://mirrors.kernel.org/gnu/gettext/gettext-0.17.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gettext"
	
	# Patch to reduce the number of superfluous things we build
	fwdpatch "$ROOTDIR/patches/gettext-Makefile.in.diff" -p0 || true
	
	if needsconfigure $@; then
		status "Configuring gettext"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS" ./configure \
			--prefix="$ROOTDIR/build" \
			--disable-static \
			--enable-shared \
			--disable-dependency-tracking
	fi
	
	status "Building and installing gettext"
	make
	make install

	# Undo all of our patches... goodbye!
	revpatch "$ROOTDIR/patches/gettext-Makefile.in.diff" -p0

	quiet popd
}

##
# glib
#
build_glib() {
	prereq "glib" \
		"ftp://ftp.gnome.org/pub/gnome/sources/glib/2.20/glib-2.20.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/glib"
	
	# We may have to apply a patch if we're building on PowerPC
	if [ "$(arch)" = "ppc" ]; then
		warning "glib may not build correctly from PowerPC."
	fi
	
	# Patch to fix building with the native libiconv
	fwdpatch "$ROOTDIR/patches/glib-gconvert.c.diff" -p0 || true
	
	# Patch to reduce the number of superfluous things we build
	fwdpatch "$ROOTDIR/patches/glib-Makefile.in.diff" -p0 || true
	
	if needsconfigure $@; then
		status "Configuring glib"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS -lintl" \
			MSGFMT="$ROOTDIR/build/bin/msgfmt" \
			PKG_CONFIG="$ROOTDIR/build/bin/pkg-config" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-static \
				--enable-shared \
				--with-libiconv=native \
				--disable-dependency-tracking
	fi
	
	status "Building and installing glib"
	make
	make install
	
	# Revert the patches
	revpatch "$ROOTDIR/patches/glib-Makefile.in.diff" -p0
	revpatch "$ROOTDIR/patches/glib-gconvert.c.diff" -p0

	quiet popd
}

##
# Meanwhile
#
build_meanwhile() {
	prereq "meanwhile" \
		"http://dl.sf.net/sourceforge/meanwhile/meanwhile-1.0.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/meanwhile"
	
	# Mikael Berthe writes, "It seems that the last guint32_get() fails when
	# Meanwhile receives the FT offer. I think we can skip it -- works for me
	# but I can't check it with an older server.
	fwdpatch "$ROOTDIR/patches/Meanwhile-srvc_ft.c.diff" -p0 || true
	
	# Fixes Awareness Snapshots with recent Sametime servers, thanks to Mikael
	# Berthe. "With recent Sametime servers there seem to be 2 bytes after the
	# Snapshot Message Blocks. This patch tries to use the end of block offset
	# provided by th server."
	fwdpatch "$ROOTDIR/patches/Meanwhile-common.c.diff" -p0 || true
	
	# Patch to fix a crash in blist parsing
	fwdpatch "$ROOTDIR/patches/Meanwhile-st_list.c.diff" -p0 || true
	
	# The provided libtool ignores our Universal Binary-makin' flags
	fwdpatch "$ROOTDIR/patches/Meanwhile-ltmain.sh.diff" -p0 || true
	
	if needsconfigure $@; then
		# Delete 'libtool' if it exists, so that we'll generate a new one 
		rm -f libtool
		
		status "Configuring Meanwhile"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS" \
			PKG_CONFIG="$ROOTDIR/build/bin/pkg-config" \
			GLIB_LIBS="$ROOTDIR/build/lib" \
			GLIB_CFLAGS="-I$ROOTDIR/build/include/glib-2.0 \
			             -I$ROOTDIR/build/lib/glib-2.0/include" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-static \
				--enable-shared \
				--disable-doxygen \
				--disable-mailme \
				--disable-dependency-tracking
	fi
	
	status "Building and installing Meanwhile"
	CFLAGS="$FLAGS" LDFLAGS="$FLAGS" make
	make install
	
	# Undo all the patches
	revpatch "$ROOTDIR/patches/Meanwhile-ltmain.sh.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-st_list.c.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-common.c.diff" -p0
	revpatch "$ROOTDIR/patches/Meanwhile-srvc_ft.c.diff" -p0
	
	quiet popd
}

##
# Gadu-Gadu
#
build_gadugadu() {
	# We used to use 1.7.1, which is pretty outdated. Is there a reason?
	prereq "gadu-gadu" \
		"http://toxygen.net/libgadu/files/libgadu-1.8.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gadu-gadu"
	
	if needsconfigure $@; then
		status "Configuring Gadu-Gadu"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS" ./configure \
			--prefix="$ROOTDIR/build" \
			--disable-static \
			--enable-shared \
			--disable-dependency-tracking
	fi
	
	status "Building and installing Gadu-Gadu"
	make
	make install
	
	quiet popd
}

##
# SIPE
#
build_sipe() {
	# I'm not sure how to build this yet... first, it looks like it expects
	# libpurple to already be built, and second it's requiring a FreeBSD package
	# called "com_err" which I can't find the source to.
	warning "I don't know how to build SIPE yet."
	return 0
	
	prereq "sipe" \
		"http://dl.sf.net/sourceforge/sipe/pidgin-sipe-1.4.0.tar.gz"
	
	quiet pushd "$ROOTDIR/source/sipe"
	
	if needsconfigure $@; then
		status "Configuring SIPE"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS" \
			PKG_CONFIG="$ROOTDIR/build/bin/pkg-config" \
			./configure \
				--prefix="$ROOTDIR/build"
				--disable-dependency-tracking
	fi
	
	status "Building and installing SIPE"
	make
	make install
	
	quiet popd
}

##
# Gfire
#
build_gfire() {
	# I'm not sure how to build this yet... it expects Pidgin to be built, and
	# since no pidgin.pc file is made, we can't satisfy that requirement.
	warning "I don't know how to build Gfire yet."
	return 0
	
	prereq "gfire" \
		"http://dl.sf.net/gfire/gfire-0.8.1.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gfire"
	
	if needsconfigure $@; then
		status "Configuring Gfire"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS" \
			PKG_CONFIG="$ROOTDIR/build/bin/pkg-config" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing Gfire"
	make
	make install
	
	quiet popd
}

##
# intltool
#
build_intltool() {
	# We used to use 0.36.2, but I switched to the latest MacPorts is using
	prereq "intltool" \
		"http://ftp.gnome.org/pub/gnome/sources/intltool/0.40/intltool-0.40.6.tar.gz"
	
	quiet pushd "$ROOTDIR/source/intltool"
	
	if needsconfigure $@; then
		status "Configuring intltool"
		./configure --prefix="$ROOTDIR/build" --disable-dependency-tracking
	fi
	
	status "Building and installing intltool"
	make
	make install
	
	quiet popd
}

##
# fetch_libpurple
#
fetch_libpurple() {
	quiet pushd "$ROOTDIR/source"
	
	if [ -d "im.pidgin.adium" ]; then
		
		status "Pulling latest changes to libpurple"
		cd "im.pidgin.adium"
		mtn pull
		mtn update
		
	else
		
		quiet mkdir "im.pidgin.adium"
		cd "im.pidgin.adium"
	
		status "Downloading bootstrap database for libpurple"
		curl -LOf "http://developer.pidgin.im/static/pidgin.mtn.bz2"
	
		status "Extracting bootstrap database"
		bzip2 -d "pidgin.mtn.bz2"
	
		status "Migrating database to new schema"
		mtn db -d "pidgin.mtn" migrate
	
		status "Pulling updates to monotone database"
		mtn -d "pidgin.mtn" pull --set-default "mtn.pidgin.im" "im.pidgin.*"
	
		status "Checking out im.pidgin.adium branch"
		mtn -d "pidgin.mtn" co -b "im.pidgin.adium" .
	
	fi
	
	quiet popd
}

##
# libpurple
#
build_libpurple() {
	fetch_libpurple
	prereq "cyrus-sasl" \
		"ftp://ftp.andrew.cmu.edu/pub/cyrus-mail/OLD-VERSIONS/sasl/cyrus-sasl-2.1.18.tar.gz"
	
	# Copy the headers from Cyrus-SASL
	status "Copying headers from Cyrus-SASL"
	quiet mkdir -p "$ROOTDIR/build/include/sasl"
	cp -f "$ROOTDIR/source/cyrus-sasl/include/"*.h "$ROOTDIR/build/include/sasl"
	
	quiet pushd "$ROOTDIR/source/im.pidgin.adium"
	
	PROTOCOLS="bonjour,facebook,gg,irc,jabber,msn,myspace,novell,oscar,qq,"
	PROTOCOLS+="sametime,simple,yahoo,zephyr"
	
	# Leopard's 64-bit Kerberos library is missing symbols, as evidenced by
	#    $ nm -arch x86_64 /usr/lib/libkrb4.dylib | grep krb_rd_req
	# So, only enable it on Snow Leopard
	if [ "$(sysctl -b kern.osrelease | awk -F '.' '{ print $1}')" -ge 10 ]; then
		KERBEROS="--with-krb4"
	else
		warning "Kerberos support is disabled."
		KERBEROS=""
	fi
	
	if needsconfigure $@; then
		status "Configuring libpurple"
		CFLAGS="$FLAGS -I/usr/include/kerberosIV \
		       -DHAVE_SSL -DHAVE_OPENSSL -fno-common" \
			ACLOCAL_FLAGS="-I $ROOTDIR/build/share/aclocal" \
				PATH="$ROOTDIR/build/bin:$PATH" \
			LDFLAGS="$FLAGS -lsasl2" \
			PATH="$ROOTDIR/build/bin:$PATH" \
			PKG_CONFIG="$ROOTDIR/build/bin/pkg-config" \
			LIBXML_CFLAGS="-I/usr/include/libxml2" \
			LIBXML_LIBS="-lxml2" \
			GADU_CFLAGS="-I$ROOTDIR/build/include" \
			GADU_LIBS="-lgadu" \
			MEANWHILE_CFLAGS="-I$ROOTDIR/build/include/meanwhile \
			                  -I$ROOTDIR/build/include/glib-2.0 \
			                  -I$ROOTDIR/build/lib/glib-2.0/include" \
			MEANWHILE_LIBS="-lmeanwhile -lglib-2.0 -liconv" \
			./autogen.sh \
				--disable-dependency-tracking \
				--disable-gtkui \
				--disable-consoleui \
				--disable-perl \
				--enable-debug \
				--disable-static \
				--enable-shared \
				--enable-cyrus-sasl \
				--prefix="$ROOTDIR/build" \
				--with-static-prpls="$PROTOCOLS" \
				--disable-plugins \
				--disable-gstreamer \
				--disable-avahi \
				--disable-dbus \
				--enable-gnutls=no \
				--enable-nss=no \
				"$KERBEROS"
	fi
	
	status "Building and installing libpurple"
	make
	make install
	
	status "Copying internal libpurple headers"
	cp -f "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/oscar/oscar.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/oscar/snactypes.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/oscar/peer.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/cmds.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/internal.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/msn/"*.h \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/yahoo/"*.h \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/gg/buddylist.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/gg/gg.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/gg/search.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/bosh.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/buddy.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/caps.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/jutil.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/presence.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/si.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/jabber.h" \
		  "$ROOTDIR/source/im.pidgin.adium/libpurple/protocols/jabber/iq.h" \
		  "$ROOTDIR/build/include/libpurple"
	
	quiet popd
}

##
# gstreamer
#
build_gstreamer() {
	prereq "gstreamer" \
		"http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-0.10.23.tar.gz"
	prereq "gstreamer-plugins-base" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-0.10.23.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gstreamer"
	
	if needsconfigure $@; then
		status "Configuring gstreamer"
		CFLAGS="$FLAGS" LDFLAGS="$FLAGS" \
			PKG_CONFIG="$ROOTDIR/build/bin/pkg-config" \
			PKG_CONFIG_PATH="$ROOTDIR/build/lib/pkgconfig:/usr/lib/pkgconfig" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing gstreamer"
	warning "Building too much! Patch the Makefile"
	make
	make install
	
	quiet popd
}

##
# make_po_files
#
make_po_files() {
	warning "Not yet implemented."
}

##
# make_framework
#
make_framework() {
	warning "Not yet implemented."
}

# Check that we're in the Dependencies directory
ROOTDIR=$(pwd)
if ! expr "$ROOTDIR" : '.*/Dependencies$' &> /dev/null; then
	error "Please run this script from the Dependencies directory."
	exit 1
fi

# The basic linker/compiler flags we'll be referring to
FLAGS="-isysroot /Developer/SDKs/MacOSX10.5.sdk \
       -arch i386 -arch x86_64 -arch ppc \
       -I$ROOTDIR/build/include \
       -L$ROOTDIR/build/lib"

# Make the source and build directories while we're here
quiet mkdir "source"
quiet mkdir "build"

# TODO: Make this parameterizable 
build_pkgconfig $@
build_gettext $@
build_glib $@

build_meanwhile $@
build_gadugadu $@

build_intltool $@
build_libpurple $@

#build_gstreamer $@

#build_sipe $@
#build_gfire $@

#make_po_files $@
#make_framework $@
