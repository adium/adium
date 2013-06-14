#!/bin/bash

OLD_DMGS="dmgs"
BUILD_DIR="build"

#list all Adium dmgs (Adium_1.7hgr5187.dmg), extract the changeset, reverse sort, and keep the top one plus 2 more
FILE_LIST=( $(ls -l1 "$OLD_DMGS"/Adium*.dmg | sed 's/.*hgr\([0-9]*\).*/\1/' | sort -rn | head -n3) )
BASE_NAME=`ls -l1 "$OLD_DMGS"/Adium*.dmg | head -n1 | sed 's/hgr[0-9]*.*/hgr/'`
VERSION=`echo $BASE_NAME | sed "s/$OLD_DMGS\/Adium_\(.*hgr\).*/\1/"`

echo "r${FILE_LIST[0]}" > "$BUILD_DIR/latestDelta.info"
echo "$VERSION${FILE_LIST[0]}" >> "$BUILD_DIR/latestDelta.info"

#mount each dmg
for dmg in ${FILE_LIST[@]} ; do
	hdiutil attach -quiet -noverify -mountpoint "./mp-$dmg" "$BASE_NAME$dmg.dmg"

	#create the delta from the current to the first
	if [ $dmg != ${FILE_LIST[0]} ]; then
        mkdir -p "$BUILD_DIR/deltas"
		DELTA_NAME="$BUILD_DIR/deltas/$dmg-${FILE_LIST[0]}.delta"
		./BinaryDelta create "./mp-$dmg/Adium.app" "./mp-${FILE_LIST[0]}/Adium.app" "$DELTA_NAME"
		LENGTH=`ls -l $DELTA_NAME | awk '{print $5}'`
        DSA_SIGNATURE=`ruby sign_update.rb $DELTA_NAME ~/adium-dsa-sign/dsa_priv.pem`
        echo "$VERSION$dmg,$LENGTH,$DELTA_NAME,$DSA_SIGNATURE" >> "$BUILD_DIR/latestDelta.info"
	fi
done

#unmount each dmg
for dmg in ${FILE_LIST[@]} ; do
	hdiutil detach "./mp-$dmg"
done

