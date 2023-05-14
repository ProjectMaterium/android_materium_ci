#!/bin/bash

FULL_HASH=$(sha256sum $finalzip_path)
export postdata="\"$FULL_HASH\": \"$FULL_DL_LINK\""
if [ -e $incremental_zip_path ]; then
    INCREMENTAL_HASH=$(sha256sum $incremental_zip_path)
    postdata="$postdata, \"$INCREMENTAL_HASH\": \"$INCREMENTAL_DL_LINK\""
fi
if [ -e "$img_path" ]; then
    RECOVERY_HASH=$(sha256sum $img_path)
    postdata="$postdata, \"$RECOVERY_HASH\": \"$RECOVERY_DL_LINK\""
fi

postdata="{$postdata}"

if wget -O- --post-data "$postdata" "$bigota_push_url" >/dev/null 2>&1; then
    echo "--- BIGOTA PUSH FAIL ---"
    exit 1
fi

unset postdata
echo "--- BIGOTA PUSH DONE ---"


ota_full_json=$("$ROM_DIR"/vendor/droid-ng/tools/make-ota-json.sh "$finalzip_path")
postdata="{\"oldIncr\":\"$ota_incr_id\", \"codename\": \"$device\", \"fullOta\": \"$ota_full_json\""
if [ "${generate_incremental}" == "true" ] && [ -e "${incremental_zip_path}" ] && [ "${old_target_files_exists}" == "true" ]; then
    ota_incr_json=$("$ROM_DIR"/vendor/droid-ng/tools/make-incr-json.sh "$incremental_zip_path") || echo "Failed to create ota json" && return 1
    postdata=$postdata", \"incrOta\": \"$ota_incr_json\""
fi
postdata="$postdata}"

wget -O- --post-data "$postdata" "$ota_base_url"/v1/registerBuild >/dev/null 2>&1
if [ $? -ne 0 ]; then
    echo "--- OTA PUSH FAIL ---"
    exit 1
fi
echo "--- OTA PUSH DONE ---"