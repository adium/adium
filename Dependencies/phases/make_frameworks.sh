#!/bin/bash -eu

##
# prep_headers
#
prep_headers() {
	## purple prereqs
	quiet mkdir "${ROOTDIR}/build/lib/include" || true
	#libintl
	status "Staging libintl headers"
	local libintlDir="${ROOTDIR}/build/lib/include/libintl-${INTL_VERSION}"
	quiet mkdir "${libintlDir}" || true
	log cp "${ROOTDIR}/build/include/libintl.h" "${libintlDir}/"
	
	#glib
	status "Staging glib headers"
	local glibDir="${ROOTDIR}/build/lib/include/libglib-${GLIB_VERSION}.0"
	quiet mkdir "${glibDir}" || true
	log cp -R "${ROOTDIR}/build/include/glib-${GLIB_VERSION}" "${glibDir}"
	log cp "${ROOTDIR}/build/lib/glib-${GLIB_VERSION}/include/glibconfig.h" \
		"${glibDir}"
	
	#gmodule
	status "Staging gmodule headers"
	local gmoduleDir="${ROOTDIR}/build/lib/include/libgmodule-${GLIB_VERSION}.0"
	quiet mkdir "${gmoduleDir}" || true
	log cp "${ROOTDIR}/build/include/glib-${GLIB_VERSION}/gmodule.h" "${gmoduleDir}"
	
	#gobject
	status "Staging gobject headers"
	local gobjectDir="${ROOTDIR}/build/lib/include/libgobject-${GLIB_VERSION}.0"
	quiet mkdir "${gobjectDir}" || true
	log cp "${ROOTDIR}/build/include/glib-${GLIB_VERSION}/glib-object.h" "${gobjectDir}"
	log cp -R "${ROOTDIR}/build/include/glib-${GLIB_VERSION}/gobject/" "${gobjectDir}"
	
	#gthread
	status "Staging gthread non-headers"
	local gthreadDir="${ROOTDIR}/build/lib/include/libgthread-${GLIB_VERSION}.0"
	quiet mkdir "${gthreadDir}" || true
	touch "${gthreadDir}/no_headers_here.txt"
	
	if $BUILD_OTR; then
	#libotr
		status "Staging libotr headers"
		local otrDir="${ROOTDIR}/build/lib/include/libotr-${OTR_VERSION}"
		quiet mkdir "${otrDir}" || true
		log cp -R "${ROOTDIR}/build/include/libotr/" "${otrDir}"
		log cp "${ROOTDIR}/build/include/gcrypt.h" "${otrDir}"
		log cp "${ROOTDIR}/build/include/gcrypt-module.h" "${otrDir}"
		log cp "${ROOTDIR}/build/include/gpg-error.h" "${otrDir}"
	else
		#meanwhile
		status "Staging meanwhile non-headers"
		local meanwhileDir="${ROOTDIR}/build/lib/include/libmeanwhile-${MEANWHILE_VERSION}"
		quiet mkdir "${meanwhileDir}" || true
		touch "${meanwhileDir}/no_headers_here.txt"
		
		#json-glib
		status "Staging json-glib headers"
		local jsonDir="${ROOTDIR}/build/lib/include/libjson-glib-${JSON_GLIB_VERSION}.0"
		quiet rm -r "${jsonDir}" || true
		quiet mkdir "${jsonDir}" || true
		log cp -R "${ROOTDIR}/build/include/json-glib-${JSON_GLIB_VERSION}/json-glib" "${jsonDir}"
		

		#libpurple
		status "Staging libpurple headers"
		local purpleDir="${ROOTDIR}/build/lib/include/libpurple-${LIBPURPLE_VERSION}"
		quiet rm -rf "${purpleDir}"
		quiet mkdir "${purpleDir}"
		log cp -R "${ROOTDIR}/build/include/libpurple" "${purpleDir}"
		status "Completed staging headers"
	fi
}

##
# make_framework
#
make_framework() {
	FRAMEWORK_DIR="${ROOTDIR}/Frameworks"
	quiet mkdir "${FRAMEWORK_DIR}"
	
	status "Making the framework. If 'Done making framework!' is not displayed, check error.log."
	
	prep_headers
	
	export PATH="${ROOTDIR}/rtool:$PATH"
	
	# resolve symlinks - rtool doesn't like lthem :(
	status "Resolving symlinks for frameworkize.py..."
	local files="${ROOTDIR}/build/lib/*.dylib"
	for file in ${files} ; do
		if [ -h ${file} ] ; then
			local resolvedLink=`/usr/bin/readlink -n ${file}`
			status "... ${file} -> ${ROOTDIR}/build/lib/${resolvedLink}"
			log rm "${file}"
			log cp "${ROOTDIR}/build/lib/${resolvedLink}" "${file}"
		fi
	done
	
	if $BUILD_OTR; then
		status "Making a framework for libotr..."
		log python "${ROOTDIR}/framework_maker/frameworkize.py" \
			"${ROOTDIR}/build/lib/libotr.${OTR_VERSION}.dylib" \
			"${FRAMEWORK_DIR}"
		
		log cp "${ROOTDIR}/Libotr-Info.plist" \
			"${FRAMEWORK_DIR}/libotr.subproj/libotr.framework/Resources/Info.plist"
	else
		status "Making a framework for libpurple-${LIBPURPLE_VERSION} and all dependencies..."
		log python "${ROOTDIR}/framework_maker/frameworkize.py" \
			"${ROOTDIR}/build/lib/libpurple.${LIBPURPLE_VERSION}.dylib" \
			"${FRAMEWORK_DIR}"

		status "Adding the Adium framework header..."
		log cp "${ROOTDIR}/libpurple-full.h" \
			"${FRAMEWORK_DIR}/libpurple.subproj/libpurple.framework/Headers/libpurple.h"

		log cp "${ROOTDIR}/Libpurple-Info.plist" \
			"${FRAMEWORK_DIR}/libpurple.subproj/libpurple.framework/Resources/Info.plist"
	fi
	
	status "Done making framework!"
}

##
# make_po_files
#
make_po_files() {
	PURPLE_RSRC_DIR="${ROOTDIR}/Frameworks/libpurple.subproj/libpurple.framework/Resources"
	
	status "Building libpurple po files"
	quiet pushd "${ROOTDIR}/source/libpurple/po"
		log make all
		log make install
	quiet popd
	
	status "Copy po files to framework"
	quiet pushd "${ROOTDIR}/build/share/locale"
		quiet mkdir "${PURPLE_RSRC_DIR}" || true
		log cp -v -r * "${PURPLE_RSRC_DIR}"
	quiet popd
	
	status "Trimming the fat..."
	quiet pushd "${PURPLE_RSRC_DIR}"
		log find . \( -name gettext-runtime.mo -or -name gettext-tools.mo -or -name glib20.mo \) -type f -delete
	quiet popd
	
	status "libpurple po files built!"
}
