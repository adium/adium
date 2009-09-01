#!/bin/bash -eu

NUMBER_OF_CORES=`sysctl -n hw.activecpu`

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
# xcompile <CFLAGS> <LDFLAGS> <configure command> <files to combine>
#
# Cycles through supported host configurations and builds, then lipo-ing them all together.
xcompile() {
	quiet mkdir "${ROOTDIR}/sandbox"
	for (( i=0; i<${#HOSTS[@]}; i++ )) ; do
		status "...configuring for ${HOSTS[i]}"
		quiet mkdir "${ROOTDIR}/sandbox/root-${ARCHS[i]}"
		export CFLAGS="${1} -arch ${ARCHS[i]}"
		export LDFLAGS="${2} -arch ${ARCHS[i]}"
		
		${3} --host="${HOSTS[i]}" --build="${HOSTS[i]}" \
			--prefix="${ROOTDIR}/sandbox/root-${ARCHS[i]}"
		
		status "...making and installing for ${HOSTS[i]}"
		make -j $NUMBER_OF_CORES
		make install
		make clean
	done
	
	# create universal
	for FILE in ${@:4} ; do
		# change library location and 
		local ext=${FILE##*.}
		local lipoFiles=""
		for ARCH in ${ARCHS[@]} ; do
			if [[ ${ext} == 'dylib' ]] ; then
				install_name_tool -id "${ROOTDIR}/build/${FILE}" \
					"${ROOTDIR}/sandbox/root-${ARCH}/${FILE}"
			fi
			lipoFiles="${lipoFiles} ${ROOTDIR}/sandbox/root-${ARCH}/${FILE}"
		done
		status "combine ${lipoFiles} to build/${FILE}"
		lipo -create ${lipoFiles} -output "${ROOTDIR}/build/${FILE}"
	done
	
	#copy headers
	local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/include/*"
	for f in ${files} ; do
		cp -R ${f} "${ROOTDIR}/build/include"
	done
	
	#copy pkgconfig files and modify prefix
	local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/pkgconfig/*"
	for f in ${files} ; do
		status "patching pkgconfig file: ${f}"
		local basename=`basename ${f}`
		local SEDREP=`echo $ROOTDIR | awk '{gsub("\\\\\/", "\\\\\\/");print}'`
		local SEDPAT="s/^prefix=.*/prefix=${SEDREP}\\/build/"
		sed -e "${SEDPAT}" "${f}" > "${ROOTDIR}/build/lib/pkgconfig/${basename}"
	done
	
	#copy .la files and modify
	local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/*.la"
	for f in ${files} ; do
		status "patching pkgconfig file: ${f}"
		local basename=`basename ${f}`
		local SEDREP=`echo $ROOTDIR | awk '{gsub("\\\\\/", "\\\\\\/");print}'`
		local SEDPAT="s/^libdir=.*/libdir=\'${SEDREP}\\/build\\/lib\'/"
		sed -e "${SEDPAT}" "${f}" > "${ROOTDIR}/build/lib/${basename}"
	done
	
	#copy symlinks in lib
	local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/*"
	for f in ${files} ; do
		if [ -h ${f} ] ; then
			cp -a ${f} "${ROOTDIR}/build/lib"
		fi
	done
	quiet rm -rf "${ROOTDIR}/sandbox"
}
##
# xconfigure <CFLAGS> <LDFLAGS> <configure command> <headers to mux>
#
# Cycles through supported host configurations and muxes platform-dependant
# headers.
# This ensures that we don't have type mismatches and compile time overflows.
xconfigure() {
	for (( i=0; i<${#HOSTS[@]}; i++ )) ; do
		status "...for ${HOSTS[i]}"
		export CFLAGS="${1} -arch ${ARCHS[i]}"
		export LDFLAGS="${2} -arch ${ARCHS[i]}"
		CONFIG_CMD="${3} --host=${HOSTS[i]}"
		${CONFIG_CMD}
		
		for FILE in ${@:4} ; do
			local ext=${FILE##*.}
			local base=${FILE:0:${#FILE}-${#ext}-1}
			mv ${FILE} ${base}-${ARCHS[i]}.${ext}
		done
	done
	
	# reconfigure *again* to set C and LD Flags right
	# Yes, it's an ugly hack, and should probably be replaced with
	# find and a sed script.
	status "...for universal build"
	export CFLAGS="${1} ${ARCH_FLAGS}"
	export LDFLAGS="${2} ${ARCH_FLAGS}"
	local self_host=`gcc -dumpmachine`
	${3}
	
	# mux headers
	for FILE in ${@:4} ; do
		status "Muxing ${FILE}..."
		local ext=${FILE##*.}
		local base=${FILE:0:${#FILE}-${#ext}-1}
		quiet rm ${FILE}
		for (( i=0; i<${#ARCHS[@]}; i++ )) ; do
			status "...for ${ARCHS[i]}"
			if [[ $i == 0 ]] ; then
				echo "#if defined (__${ARCHS[i]}__)" > ${FILE}
			else
				echo "#elif defined (__${ARCHS[i]}__)" >> ${FILE}
			fi
			cat ${base}-${ARCHS[i]}.${ext} >> ${FILE}
		done
		echo "#else" >> ${FILE}
		echo "#error This isn't a recognized platform." >> ${FILE}
		echo "#endif" >> ${FILE} 
		status "...${FILE} muxed"
	done	
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
	make -j $NUMBER_OF_CORES
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
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" ./configure \
			--prefix="$ROOTDIR/build" \
			--disable-java \
			--disable-static \
			--enable-shared \
			--disable-dependency-tracking
		#xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
		#	"${ROOTDIR}/source/gettext/gettext-tools/config.h" \
		#	"${ROOTDIR}/source/gettext/gettext-runtime/config.h" \
		#	"${ROOTDIR}/source/gettext/gettext-runtime/libasprintf/config.h"
	fi
	
	status "Building and installing gettext"
	make -j $NUMBER_OF_CORES
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
		export MSGFMT="${ROOTDIR}/build/bin/msgfmt"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-static \
				--enable-shared \
				--with-libiconv=native \
				--disable-fam \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS} -lintl" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/glib/config.h" \
			"${ROOTDIR}/source/glib/gmodule/gmoduleconf.h" \
			"${ROOTDIR}/source/glib/glibconfig.h"
	fi
	
	status "Building and installing glib"
	make -j $NUMBER_OF_CORES
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
		"http://downloads.sourceforge.net/project/meanwhile/meanwhile/1.0.2/meanwhile-1.0.2.tar.gz"
	
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
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
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
	CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" make -j $NUMBER_OF_CORES
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
		CONFIG_CMD="./configure \
			--prefix=$ROOTDIR/build \
			--disable-static \
			--enable-shared \
			--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gadu-gadu/config.h" \
			"${ROOTDIR}/source/gadu-gadu/include/libgadu.h"
	fi
	
	status "Building and installing Gadu-Gadu"
	make -j $NUMBER_OF_CORES
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
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build"
				--disable-dependency-tracking
	fi
	
	status "Building and installing SIPE"
	make -j $NUMBER_OF_CORES
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
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing Gfire"
	make -j $NUMBER_OF_CORES
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
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# json-glib
#
build_jsonglib() {
	prereq "json-glib" \
		"http://folks.o-hand.com/~ebassi/sources/json-glib-0.6.2.tar.gz"
	
	quiet pushd "$ROOTDIR/source/json-glib"
	
	if needsconfigure $@; then
		status "Configuring json-glib"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			GLIB_LIBS="$ROOTDIR/build/lib" \
			GLIB_CFLAGS="-I$ROOTDIR/build/include/glib-2.0 \
			             -I$ROOTDIR/build/lib/glib-2.0/include" \
			./configure \
			--prefix="$ROOTDIR/build" \
			--disable-dependency-tracking
	fi
	
	status "Building and installing json-glib"
	make -j $NUMBER_OF_CORES
	make install
	
	# C'mon, why do you make me do this?
	ln -fs "$ROOTDIR/build/include/json-glib-1.0/json-glib" \
		"$ROOTDIR/build/include/json-glib"
	
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
		$MTN pull
		$MTN update
		
	else
		
		quiet mkdir "im.pidgin.adium"
		cd "im.pidgin.adium"
	
		status "Downloading bootstrap database for libpurple"
		curl -LOf "http://developer.pidgin.im/static/pidgin.mtn.bz2"
	
		status "Extracting bootstrap database"
		bzip2 -d "pidgin.mtn.bz2"
	
		status "Migrating database to new schema"
		$MTN db -d "pidgin.mtn" migrate
	
		status "Pulling updates to monotone database"
		$MTN -d "pidgin.mtn" pull --set-default "mtn.pidgin.im" "im.pidgin.*"
	
		status "Checking out im.pidgin.adium.1-4 branch"
		$MTN -d "pidgin.mtn" co -b "im.pidgin.adium.1-4" .
	
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
		#KERBEROS="--with-krb4"
		KERBEROS=""
	else
		warning "Kerberos support is disabled."
		KERBEROS=""
	fi
	
	if needsconfigure $@; then
		status "Configuring libpurple"
		export ACLOCAL_FLAGS="-I $ROOTDIR/build/share/aclocal"
		export LIBXML_CFLAGS="-I/usr/include/libxml2"
		export LIBXML_LIBS="-lxml2"
		export GADU_CFLAGS="-I$ROOTDIR/build/include"
		export GADU_LIBS="-lgadu"
		export MEANWHILE_CFLAGS="-I$ROOTDIR/build/include/meanwhile \
			-I$ROOTDIR/build/include/glib-2.0 \
			-I$ROOTDIR/build/lib/glib-2.0/include"
		export MEANWHILE_LIBS="-lmeanwhile -lglib-2.0 -liconv"
		CONFIG_CMD="./autogen.sh \
				--disable-dependency-tracking \
				--disable-gtkui \
				--disable-consoleui \
				--disable-perl \
				--enable-debug \
				--disable-static \
				--enable-shared \
				--enable-cyrus-sasl \
				--prefix=$ROOTDIR/build \
				--with-static-prpls=$PROTOCOLS \
				--disable-plugins \
				--disable-avahi \
				--disable-dbus \
				--enable-gnutls=no \
				--enable-nss=no \
				--enable-vv=yes \
				--disable-idn \
				$KERBEROS"
		xconfigure "$BASE_CFLAGS -I/usr/include/kerberosIV -DHAVE_SSL \
			        -DHAVE_OPENSSL -fno-common" \
			"$BASE_LDFLAGS -lsasl2 -ljson-glib-1.0" \
			"${CONFIG_CMD}" \
			"${ROOTDIR}/source/im.pidgin.adium/libpurple/purple.h" \
			"${ROOTDIR}/source/im.pidgin.adium/config.h"
	fi
	
	status "Building and installing libpurple"
	make -j $NUMBER_OF_CORES
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
# xml2
#
build_libxml2() {
	prereq "xml2" \
		"ftp://xmlsoft.org:21//libxml2/libxml2-sources-2.7.3.tar.gz"
	
	quiet pushd "$ROOTDIR/source/xml2"
	
	if needsconfigure $@; then
		status "Configuring xml2"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--with-python=no \
				--disable-dependency-tracking
	fi
	
	status "Building and installing xml2"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}


##
# liboil
# liboil needs special threatment.  Rather than placing platform specific code
# in a ifdef, it sequesters it by directory and invokes a makefile.  woowoo.
build_liboil() {
	prereq "oil" \
		"http://liboil.freedesktop.org/download/liboil-0.3.16.tar.gz"
	
	quiet pushd "$ROOTDIR/source/oil"
	
	status "Cross-comiling oil..."
	CONFIG_CMD="./configure \
				--disable-dependency-tracking"
	xcompile "${BASE_CFLAGS}  -DHAVE_SYMBOL_UNDERSCORE" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
		"lib/liboil-0.3.0.dylib" \
		"lib/liboil-0.3.a"

	status "...done cross-compiling oil"
	
	quiet popd
}

##
# gst-plugins-base
#
build_gst_plugins_base() {
	prereq "gst-plugins-base" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-base/gst-plugins-base-0.10.23.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-base"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-base"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-base/config.h" \
			"${ROOTDIR}/source/gst-plugins-base/_stdint.h"
	fi
	
	status "Building and installing gst-plugins-base"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gst-plugins-good
#
build_gst_plugins_good() {
	prereq "gst-plugins-good" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-good/gst-plugins-good-0.10.15.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-good"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-good"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-aalib \
				--disable-examples \
				--disable-goom \
				--disable-goom2k1 \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-good/config.h" \
			"${ROOTDIR}/source/gst-plugins-good/_stdint.h"
	fi
	
	status "Building and installing gst-plugins-good"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gst-plugins-bad
#
build_gst_plugins_bad() {
	prereq "gst-plugins-bad" \
		"http://gstreamer.freedesktop.org/src/gst-plugins-bad/gst-plugins-bad-0.10.13.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-bad"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-bad"
		export NM="nm -arch all"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-real \
				--disable-osx_video \
				--disable-quicktime \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"${ROOTDIR}/source/gst-plugins-bad/config.h" \
			"${ROOTDIR}/source/gst-plugins-bad/_stdint.h"
	fi
	
	status "Building and installing gst-plugins-bad"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gst-plugins-farsight
#
build_gst_plugins_farsight() {
	prereq "gst-plugins-farsight" \
		"http://farsight.freedesktop.org/releases/gst-plugins-farsight/gst-plugins-farsight-0.12.11.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gst-plugins-farsight"
	
	if needsconfigure $@; then
		status "Configuring gst-plugins-farsight"
		export NM="nm -arch all"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing gst-plugins-farsight"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# gstreamer plugins
#
build_gst_plugins() {
	build_liboil $@
	build_gst_plugins_base $@
	build_gst_plugins_good $@
	build_gst_plugins_bad $@
	build_gst_plugins_farsight $@
}

##
# gstreamer
#
build_gstreamer() {
    build_libxml2 $@

	prereq "gstreamer" \
		"http://gstreamer.freedesktop.org/src/gstreamer/gstreamer-0.10.24.tar.gz"
	
	quiet pushd "$ROOTDIR/source/gstreamer"
	
	if needsconfigure $@; then
		status "Configuring gstreamer"
		CONFIG_CMD="./configure \
				--prefix=$ROOTDIR/build \
				--disable-dependency-tracking"
		xconfigure "${BASE_CFLAGS}" "${BASE_LDFLAGS}" "${CONFIG_CMD}" \
			"$ROOTDIR/source/gstreamer/gst/gstconfig.h" \
			"$ROOTDIR/source/gstreamer/config.h"
	fi
	
	status "Building and installing gstreamer"
	warning "Building too much! Patch the Makefile"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
	
	build_gst_plugins $@
}

##
# libNICE
#
build_nice() {
	prereq "nice" \
		"http://nice.freedesktop.org/releases/libnice-0.0.9.tar.gz"
	
	quiet pushd "$ROOTDIR/source/nice"
	
	if needsconfigure $@; then
		status "Configuring NICE"
		export NM="nm -arch all"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-dependency-tracking
	fi
	
	status "Building and installing NICE"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# farsight
#
build_farsight() {
	build_nice $@
	
	prereq "farsight" \
		"http://farsight.freedesktop.org/releases/farsight2/farsight2-0.0.14.tar.gz"
	
	quiet pushd "$ROOTDIR/source/farsight"
	
	if needsconfigure $@; then
		status "Configuring farsight"
		export NM="nm -arch all"
		CFLAGS="$ARCH_CFLAGS" LDFLAGS="$ARCH_LDFLAGS" \
			./configure \
				--prefix="$ROOTDIR/build" \
				--disable-python \
				--disable-dependency-tracking
	fi
	
	status "Building and installing farsight"
	make -j $NUMBER_OF_CORES
	make install
	
	quiet popd
}

##
# prep_headers
#
prep_headers() {
	GLIB_VERSION=2.0
	GSTREAMER_VERSION=0.10
	INTL_VERSION=8
	JSON_GLIB_VERSION=1.0
	MEANWHILE_VERSION=1
	XML_VERSION=2.2
	LIBPURPLE_VERSION=0.6.0
	
	## purple prereqs
	quiet mkdir "${ROOTDIR}/build/lib/include" || true
	#libintl
	status "Staging libintl headers"
	local libintlDir="${ROOTDIR}/build/lib/include/libintl-${INTL_VERSION}"
	quiet mkdir "${libintlDir}" || true
	cp "${ROOTDIR}/build/include/libintl.h" "${libintlDir}/"
	
	#glib
	status "Staging glib headers"
	local glibDir="${ROOTDIR}/build/lib/include/libglib-${GLIB_VERSION}.0"
	cp -R "${ROOTDIR}/build/include/glib-${GLIB_VERSION}" "${glibDir}/"
	
	#gmodule
	status "Staging gmodule headers"
	local gmoduleDir="${ROOTDIR}/build/lib/include/libgmodule-${GLIB_VERSION}.0"
	quiet mkdir "${gmoduleDir}" || true
	cp "${ROOTDIR}/build/include/glib-${GLIB_VERSION}/gmodule.h" "${gmoduleDir}"
	
	#gobject
	status "Staging gobject headers"
	local gobjectDir="${ROOTDIR}/build/lib/include/libgobject-${GLIB_VERSION}.0"
	quiet mkdir "${gobjectDir}" || true
	cp "${ROOTDIR}/build/include/glib-${GLIB_VERSION}/glib-object.h" "${gobjectDir}"
	cp -R "${ROOTDIR}/build/include/glib-${GLIB_VERSION}/gobject/" "${gobjectDir}"
	
	#gthread
	status "Staging gthread non-headers"
	local gthreadDir="${ROOTDIR}/build/lib/include/libgthread-${GLIB_VERSION}.0"
	quiet mkdir "${gthreadDir}" || true
	touch "${gthreadDir}/no_headers_here.txt"
	
	#meanwhile
	status "Staging meanwhile non-headers"
	local meanwhileDir="${ROOTDIR}/build/lib/include/libmeanwhile-${MEANWHILE_VERSION}"
	quiet mkdir "${meanwhileDir}" || true
	touch "${meanwhileDir}/no_headers_here.txt"
	
	#json-glib
	status "Staging json-glib headers"
	local jsonDir="${ROOTDIR}/build/lib/include/libjson-glib-${JSON_GLIB_VERSION}.0"
	quiet mkdir "${jsonDir}" || true
	cp -R "${ROOTDIR}/build/include/json-glib-${JSON_GLIB_VERSION}/json-glib" "${jsonDir}"
	
	## VV stuff
	
	#gstreamer
	status "Staging gstreamer and plugins headers"
	local gstDir="${ROOTDIR}/build/lib/include/libgstreamer-${GSTREAMER_VERSION}.0"
	cp -R "${ROOTDIR}/build/include/gstreamer-${GSTREAMER_VERSION}" "${gstDir}"
	
	local non_includes=( "libgstbase-${GSTREAMER_VERSION}.0" \
						 "libgstfarsight-${GSTREAMER_VERSION}.0" \
						 "libgstinterfaces-${GSTREAMER_VERSION}.0" )
	for no_include_lib in ${non_includes[@]} ; do
		quiet mkdir "${ROOTDIR}/build/lib/include/${no_include_lib}" || true
		touch "${ROOTDIR}/build/lib/include/${no_include_lib}/no_headers_here.txt"
	done
	
	#libxml
	status "Staging libxml headers"
	local xml2Dir="${ROOTDIR}/build/lib/include/libxml-${XML_VERSION}"
	quiet mkdir "${xml2Dir}" || true
	cp -R "${ROOTDIR}/build/include/libxml2" "${xml2Dir}"
	
	#libpurple
	status "Staging libpurple headers"
	local purpleDir="${ROOTDIR}/build/lib/include/libpurple-${LIBPURPLE_VERSION}"
	quiet rm -rf "${purpleDir}"
	cp -R "${ROOTDIR}/build/include/libpurple" "${purpleDir}"
	cp "${ROOTDIR}/build/include/libgadu.h" "${purpleDir}/"
	status "Completed staging headers"
}

##
# make_framework
#
make_framework() {
	FRAMEWORK_DIR="${ROOTDIR}/Frameworks"
	quiet mkdir "${FRAMEWORK_DIR}"
	
	prep_headers
	
	export PATH="${ROOTDIR}/rtool:$PATH"
	
	# resolve symlinks - rtool doesn't like lthem :(
	status "Resolving symlinks for frameworkize.py..."
	local files="${ROOTDIR}/build/lib/*.dylib"
	for file in ${files} ; do
		if [ -h ${file} ] ; then
			local resolvedLink=`/usr/bin/readlink -n ${file}`
			status "... ${file} -> ${ROOTDIR}/build/lib/${resolvedLink}"
			rm "${file}"
			cp "${ROOTDIR}/build/lib/${resolvedLink}" "${file}"
		fi
	done
	
	status "Making a framework for libpurple-${LIBPURPLE_VERSION} and all dependencies..."
	python "${ROOTDIR}/framework_maker/frameworkize.py" \
		"${ROOTDIR}/build/lib/libpurple.${LIBPURPLE_VERSION}.dylib" \
		"${FRAMEWORK_DIR}"
	
	status "Adding the Adium framework header..."
	cp "${ROOTDIR}/libpurple-full.h" \
		"${FRAMEWORK_DIR}/libpurple.subproj/libpurple.framework/Headers/libpurple.h"

	cp "${ROOTDIR}/Libpurple-Info.plist" \
		"${FRAMEWORK_DIR}/libpurple.subproj/libpurple.framework/Resources/Info.plist"
	
	status "Done!"
}

##
# make_po_files
#
make_po_files() {
	PURPLE_RSRC_DIR="${ROOTDIR}/Frameworks/libpurple.subproj/libpurple.framework/Resources"
	
	status "Building libpurple po files"
	quiet pushd "${ROOTDIR}/source/im.pidgin.adium/po"
		make all
		make install
	quiet popd
	
	status "Copy po files to frameowrk"
	quiet pushd "${ROOTDIR}/build/share/locale"
		quiet mkdir "${PURPLE_RSRC_DIR}" || true
		cp -v -r * "${PURPLE_RSRC_DIR}"
	quiet popd
	
	status "Trimming the fat..."
	quiet pushd "${PURPLE_RSRC_DIR}"
		find . \( -name gettext-runtime.mo -or -name gettext-tools.mo -or -name glib20.mo \) -type f -delete
	quiet popd
	
	status "libpurple po files built!"
}

# Check that we're in the Dependencies directory
ROOTDIR=$(pwd)
if ! expr "$ROOTDIR" : '.*/Dependencies$' &> /dev/null; then
	error "Please run this script from the Dependencies directory."
	exit 1
fi

TARGET_BASE="apple-darwin10"

# Arrays for archs and host systems, sometimes an -arch just isnt enough!
ARCHS=( "x86_64" "i386" "ppc" )
HOSTS=( "x86_64-${TARGET_BASE}" "i686-${TARGET_BASE}" "powerpc-${TARGET_BASE}" )

SDK_ROOT="/Developer/SDKs/MacOSX10.5.sdk"
MIN_OS_VERSION="10.5"
# The basic linker/compiler flags we'll be referring to
BASE_CFLAGS="-isysroot $SDK_ROOT \
	-mmacosx-version-min=$MIN_OS_VERSION \
	-I$ROOTDIR/build/include \
	-L$ROOTDIR/build/lib"
BASE_LDFLAGS="-mmacosx-version-min=$MIN_OS_VERSION \
	-Wl,-syslibroot,$SDK_ROOT \
	-Wl,-headerpad_max_install_names \
	-I$ROOTDIR/build/include \
	-L$ROOTDIR/build/lib"

ARCH_FLAGS=""
for ARCH in ${ARCHS[@]} ; do
	ARCH_FLAGS="${ARCH_FLAGS} -arch ${ARCH}"
done

ARCH_CFLAGS="${BASE_CFLAGS} ${ARCH_FLAGS}"
ARCH_LDFLAGS="${BASE_LDFLAGS} ${ARCH_FLAGS}"

# Ok, so we keep running into issues where MacPorts will volunteer to supply
# dependencies that we want to build ourselves. On the other hand, maybe we
# rely on MacPorts for stuff like monotone.
MTN=`which mtn`
export PATH=$ROOTDIR/build/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/Developer/usr/bin:/Developer/usr/sbin
export PKG_CONFIG="$ROOTDIR/build/bin/pkg-config"
export PKG_CONFIG_PATH="$ROOTDIR/build/lib/pkgconfig:/usr/lib/pkgconfig"

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
build_jsonglib $@

build_gstreamer $@
build_farsight $@

build_libpurple $@
make_framework $@
make_po_files $@

#build_sipe $@
#build_gfire $@
