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
# log <command>
#
# Logs the given commands output to $LOG_FILE
#

stampErr() {
	while IFS='' read -r line; do echo "[ERROR]: $line" >> ${LOG_FILE}; done
}

stampLog() {
	while IFS='' read -r line; do echo "[INFO]: $line" >> ${LOG_FILE}; done
}

log() {
	local localPWD=`pwd`
	echo "

Running command:
	${localPWD}/${@:1}
" >> ${LOG_FILE}

	(
		${@:1}
	) > >(stampLog) 2> >(stampErr)
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
	
	if $FORCE_CONFIGURE; then
		needsconfig=true
		quiet make clean
	fi
	
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
		error "Couldn't autodetect file type of $2 for $1"
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

	# ensure we don't have old object files laying around
	quiet make clean
	
	# first check that we, in fact, have declared arches to build against
	# if not, just do a native build.
	if ${NATIVE_BUILD} ; then
		status "...configuring for native host"
		(
		export CFLAGS="${1}"
		export LDFLAGS="${2}"
		
		log ${3} --prefix="$ROOTDIR/build"
		
		status "...making and installing for native host"
		log make -j $NUMBER_OF_CORES
		log make install
		)
		# we're done now, exit early
		return

	# Things are simpler if we only have one arch to build, too.
	elif [[ 1 == ${#ARCHS[@]} ]] ; then
		status "...configuring for ${ARCH[0]} Only"
		(
		export CFLAGS="${1}"
		export LDFLAGS="${2}"
		
		log ${3} --host="${HOSTS[0]}" --build="${HOSTS[0]}" \
			--prefix="$ROOTDIR/build" 
		
		status "...making and installing for ${ARCH[0]} Only"
		log make -j $NUMBER_OF_CORES
		log make install
		)
		# we're done now, exit early
		return
	fi
	
	quiet mkdir "${ROOTDIR}/sandbox"
	for (( i=0; i<${#HOSTS[@]}; i++ )) ; do
	(
		status "...configuring for ${HOSTS[i]}"
		quiet mkdir "${ROOTDIR}/sandbox/root-${ARCHS[i]}"
		export CFLAGS="${1} -arch ${ARCHS[i]}"
		export LDFLAGS="${2} -arch ${ARCHS[i]}"
		local arch=`arch`
		log ${3} --host="${HOSTS[i]}" --build="${HOSTS[i]}" \
			--prefix="${ROOTDIR}/sandbox/root-${ARCHS[i]}"
		
		status "...making and installing for ${HOSTS[i]}"
		log make -j $NUMBER_OF_CORES
		log make install
		quiet make clean
	)
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
		log cp -R ${f} "${ROOTDIR}/build/include"
	done
	
	#copy bin
	cp -R "${ROOTDIR}/sandbox/root-${ARCHS[0]}/bin/" \
		"${ROOTDIR}/build/bin"
	
	#copy pkgconfig files and modify prefix
	if [ -d "${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/pkgconfig" ] ; then
		local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/pkgconfig/*"
		for f in ${files} ; do
			status "patching pkgconfig file: ${f}"
			local basename=`basename ${f}`
			local SEDREP=`echo $ROOTDIR | awk '{gsub("\\\\\/", "\\\\\\/");print}'`
			local SEDPAT="s/^prefix=.*/prefix=${SEDREP}\\/build/"
			sed -e "${SEDPAT}" "${f}" > "${ROOTDIR}/build/lib/pkgconfig/${basename}"
		done
	fi
	
	#copy .la files and modify
	local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/*.la"
	for f in ${files} ; do
		status "patching .la file: ${f}"
		local basename=`basename ${f}`
		local SEDREP=`echo $ROOTDIR | awk '{gsub("\\\\\/", "\\\\\\/");print}'`
		local SEDPAT="s/^libdir=.*/libdir=\'${SEDREP}\\/build\\/lib\'/"
		sed -e "${SEDPAT}" "${f}" > "${ROOTDIR}/build/lib/${basename}"
	done
	
	#copy symlinks in lib
	local files="${ROOTDIR}/sandbox/root-${ARCHS[0]}/lib/*"
	for f in ${files} ; do
		if [ -h ${f} ] ; then
			log cp -a ${f} "${ROOTDIR}/build/lib"
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

	# just do a native configure if no archs are given
	if ${NATIVE_BUILD} ; then
		status "...configuring for native host"
		(
		export CFLAGS="${1}"
		export LDFLAGS="${2}"
		
		log ${3}
		)
		# we're done here
		return
	fi
	for (( i=0; i<${#HOSTS[@]}; i++ )) ; do
		status "...for ${HOSTS[i]}"
		(
		export CFLAGS="${1} -arch ${ARCHS[i]}"
		export LDFLAGS="${2} -arch ${ARCHS[i]}"
		CONFIG_CMD="${3} --host=${HOSTS[i]} --build=${HOSTS[i]}"
		log ${CONFIG_CMD}
		)
		#only do this for more than 1 arch
		if [[ 1 < ${#ARCHS[@]} ]] ; then
			for FILE in ${@:4} ; do
				local ext=${FILE##*.}
				local base=${FILE:0:${#FILE}-${#ext}-1}
				mv ${FILE} ${base}-${ARCHS[i]}.${ext}
			done
		fi
	done
	
	#only do this for more than 1 arch
	if [[ 1 < ${#ARCHS[@]} ]] ; then
		# reconfigure *again* to set C and LD Flags right
		# Yes, it's an ugly hack, and should probably be replaced with
		# find and a sed script.
		status "...for universal build"
		(
		export CFLAGS="${1} ${ARCH_FLAGS}"
		export LDFLAGS="${2} ${ARCH_FLAGS}"
		local self_host=`gcc -dumpmachine`
		log ${3}
		)
		
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
	fi
}