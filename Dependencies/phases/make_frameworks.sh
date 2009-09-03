#!/bin/bash -eu

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
	LIBPURPLE_VERSION=0.6.2
	
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
	quiet mkdir "${glibDir}" || true
	cp -R "${ROOTDIR}/build/include/glib-${GLIB_VERSION}" "${glibDir}"
	cp "${ROOTDIR}/build/lib/glib-${GLIB_VERSION}/include/glibconfig.h" \
		"${glibDir}"
	
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
	quiet mkdir "${gstDir}" || true
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