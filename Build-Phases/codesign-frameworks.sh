####
# Deep sign the libotr and libpurple frameworks; ineffably, they don't sign properly when Code Sign On Copy is enabled -evands 11-14-2019
####
codesign -f --verbose=4 --deep -s "${CODE_SIGN_IDENTITY}" "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/libotr.framework/Versions/Current"
codesign -f --verbose=4 --deep -s "${CODE_SIGN_IDENTITY}" "${BUILT_PRODUCTS_DIR}/${FRAMEWORKS_FOLDER_PATH}/libpurple.framework/Versions/Current"
