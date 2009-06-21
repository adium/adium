#!/bin/sh

source common.sh
setupDirStructure
cd "$BUILDDIR"

LOG_FILE="$LOGDIR/purple_dep_make.log"
echo "Beginning build at" `date` > $LOG_FILE 2>&1
echo "Beginning build at" `date`

# Meanwhile
# Apply patches
MEANWHILE_PATCHES=("$PATCHDIR/meanwhile_ft_newservers_fix_1626349.diff" \
    "$PATCHDIR/meanwhile_prescence_newservers_fix_1626349.diff" \
    "$PATCHDIR/meanwhile_blist_parsing_crash_fix.diff")

echo "Patching Meanwhile..."

pushd "$SOURCEDIR/$MEANWHILE" > /dev/null 2>&1
    for patch in ${MEANWHILE_PATCHES[@]} ; do
        echo "Applying $patch"
    	patch --forward -p0 < $patch || true
    done
popd > /dev/null 2>&1

for ARCH in ppc i386 ; do
	echo "Building Meanwhile for $ARCH"

    export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
    
	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
			 export PATH="$PATH_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig";;
	esac

    mkdir meanwhile-$ARCH || true
    cd meanwhile-$ARCH
	
	echo '  Configuring...'
    "$SOURCEDIR/$MEANWHILE/configure" \
    	--prefix=$TARGET_DIR \
    	--enable-static --enable-shared \
    	--disable-doxygen \
    	--disable-mailme >> $LOG_FILE 2>&1

    # We edit libtool before we run make. This is evil and makes me sad.
    echo '  Editing libtool...'
    cat libtool | sed 's%archive_cmds="\\\$CC%archive_cmds="\\\$CC $BASE_LDFLAGS -arch '$ARCH'%' > libtool.tmp
    mv libtool.tmp libtool

	echo '  make && make install'
    make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1

    cd ..
done

echo "Unpatching Meanwhile..."

pushd "$SOURCEDIR/$MEANWHILE" > /dev/null 2>&1
    for patch in ${MEANWHILE_PATCHES[@]} ; do
		patch -R -p0 < $patch || true
	done
popd > /dev/null 2>&1

# Gadu-gadu
for ARCH in ppc i386 ; do
	echo "Building Gadu-Gadu for $ARCH"

	export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"
	
	case $ARCH in
		ppc) HOST=powerpc-apple-darwin9
			 export PATH="$PATH_PPC"
			 TARGET_DIR="$TARGET_DIR_PPC"
			 export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig";;
		i386) HOST=i686-apple-darwin9
  		      TARGET_DIR="$TARGET_DIR_I386"
			  export PATH="$PATH_I386"
			  export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig";;
	esac
	
	mkdir gadu-$ARCH || true
	cd gadu-$ARCH

	echo '  Configuring...'
	"$SOURCEDIR/$GADU/configure" \
		--prefix=$TARGET_DIR \
	    --enable-shared \
	    --host=$HOST >> $LOG_FILE 2>&1

	echo '  make && make install'
	make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
	cd ..
done

# intltool so pidgin will configure
# need a native intltool in both ppc and i386
for ARCH in ppc i386 ; do
	echo "Building intltool for $ARCH"

    mkdir intltool-$ARCH || true
    cd intltool-$ARCH

    case $ARCH in
        ppc) TARGET_DIR="$TARGET_DIR_PPC" ;;
        i386) TARGET_DIR="$TARGET_DIR_I386" ;;
    esac

	echo '  Configuring...'   
    "$SOURCEDIR/$INTLTOOL/configure" --prefix=$TARGET_DIR >> $LOG_FILE 2>&1
    
	echo '  make && make install'
    make -j $NUMBER_OF_CORES >> $LOG_FILE 2>&1 && make install >> $LOG_FILE 2>&1
    cd ..
done

# json-glib for the facebook prpl
for ARCH in ppc i386 ; do
	echo "Building json-glib for $ARCH"

	export CFLAGS="$BASE_CFLAGS -arch $ARCH"
	export CXXFLAGS="$CFLAGS"
	export LDFLAGS="$BASE_LDFLAGS -arch $ARCH"

    mkdir json-glib-$ARCH || true
    cd json-glib-$ARCH

	case $ARCH in
		ppc) TARGET_DIR="$TARGET_DIR_PPC"
    		export PATH="$PATH_PPC"
            export PKG_CONFIG_PATH="$TARGET_DIR_PPC/lib/pkgconfig";;
		i386) TARGET_DIR="$TARGET_DIR_I386"
            export PATH="$PATH_I386"
            export PKG_CONFIG_PATH="$TARGET_DIR_I386/lib/pkgconfig";;
	esac

	echo '  Configuring...'   
    "$SOURCEDIR/$JSONLIB/configure" --prefix=$TARGET_DIR #>> $LOG_FILE 2>&1
    
	echo '  make && make install'
    make -j $NUMBER_OF_CORES && make install #>> $LOG_FILE 2>&1
    cd ..
done

echo "Done - now run ./purple_make.sh"
