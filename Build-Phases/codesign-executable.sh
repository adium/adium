####
# Deep sign the built executable with the current code signing identity. This is a fix for Xcode's faulty handling of frameworks;
# without this step, the framework bundle fails to sign because the binary itself isn't yet signed. (?!?) -evands 11-14-2019
####
codesign -f -v --deep -s "${CODE_SIGN_IDENTITY}" "${BUILT_PRODUCTS_DIR}/${EXECUTABLE_PATH}"
