#!/bin/sh

lib_name="${EXECUTABLE_PREFIX}${PRODUCT_NAME}.${EXECUTABLE_EXTENSION}"
lib_base_name="$(echo $lib_name | awk -F '-' '{print $1}')"
dest_lib_root="${SRCROOT}/.."

echo "remove old library $lib_base_name*.${EXECUTABLE_EXTENSION}"
find "$dest_lib_root" -d 1 -name "$lib_base_name*.${EXECUTABLE_EXTENSION}" -exec rm {} \;
echo "copy $lib_name from ${TARGET_BUILD_DIR} to $dest_lib_root"
cp "${TARGET_BUILD_DIR}/$lib_name" "$dest_lib_root"


