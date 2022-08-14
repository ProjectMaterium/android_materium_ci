#!/bin/bash

export outdir="${ROM_DIR}/out/target/product/${device}"
export incrdir="${WORKSPACE}/incr"
BUILD_START=$(date +"%s")
echo "Build started for ${device}"
if [ "${jenkins}" == "true" ]; then
    telegram -M "Build ${BUILD_DISPLAY_NAME} started for ${device}: [See Progress](${BUILD_URL}console)"
else
    telegram -M "Build started for ${device}"
fi
source build/envsetup.sh
source "${my_dir}/config.sh"
export IS_CIENV=true
if [ -z "${buildtype}" ]; then
    export buildtype="userdebug"
fi
if [ "${ccache}" == "true" ] && [ -n "${ccache_size}" ]; then
    export USE_CCACHE=1
    ccache -M "${ccache_size}G"
elif [ "${ccache}" == "true" ] && [ -z "${ccache_size}" ]; then
    echo "Please set the ccache_size variable in your config."
    exit 1
fi
if [ ! -z "${rom_vendor_name}" ]; then
    lunch "${rom_vendor_name}_${device}-${buildtype}"
else
    lunch "${device}-${buildtype}"
fi
if [ "${clean}" == "clean" ]; then
    m clean -j$(nproc --all)
elif [ "${clean}" == "installclean" ]; then
    m installclean -j$(nproc --all)
    rm -rf out/target/product/"${device}"/obj/DTBO_OBJ
else
    rm "${outdir}"/*$(date +%Y)*.zip*
fi
m "${bacon}" -j$(nproc --all)
buildsuccessful="${?}"
BUILD_END=$(date +"%s")
BUILD_DIFF=$((BUILD_END - BUILD_START))

if [ "${generate_incremental}" == "true" ]; then
    if [ -e "${incrdir}/${device}.zip" ]; then
        export old_target_files_exists=true
        export old_target_files_path=$(ls "${incrdir}/${device}.zip" | tail -n -1)
        export old_incr_ver=$(cat $(ls "${incrdir}/${device}.txt" | tail -n -1))
    else
        echo "Old target-files package not found, generating incremental package on next build"
    fi
    export new_target_files_path=$(ls "${outdir}"/obj/PACKAGING/target_files_intermediates/*target_files*.zip | tail -n -1)
    if [ "${old_target_files_exists}" == "true" ]; then
        ota_from_target_files -i "${old_target_files_path}" "${new_target_files_path}" "${outdir}"/incremental_ota_update.zip
        export incremental_zip_path=$(ls "${outdir}"/incremental_ota_update.zip | tail -n -1)
        export incrOta=$("${ROM_DIR}/vendor/droid-ng/tools/incr-ota-json.sh" "$incremental_zip_path")
    fi
    cp "${new_target_files_path}" "${incrdir}/${device}.zip"
    awk -F= -v value="ro.build.version.incremental" '!/#/ && $1 == value {OFS="=";$1="";print substr($0,2)}' "$OUT/system/build.prop" > "${incrdir}/${device}.txt"
fi

export finalzip_path="$outdir/"$(ls "${outdir}" | grep -E "^droid-ng-(.*).zip$" | tail -n -1)
if [ "${LINEAGE_BUILDTYPE}" == "NIGHTLY" ]; then
    export finalzip_path="$outdir/"$(ls "${outdir}" | grep -E "^droid-ng(.*)$(date +%Y%m%d)-NIGHTLY(.*).zip$" | tail -n -1)
fi
if [ "${upload_recovery}" == "true" ]; then
    if [ ! -e "${outdir}"/recovery.img ]; then
        cp "${outdir}"/boot.img "${outdir}"/recovery.img
    fi
    export img_path=$(ls "${outdir}"/recovery.img | tail -n -1)
fi
export zip_name=$(echo "${finalzip_path}" | sed "s|${outdir}/||")
export tag=$( echo "$(env TZ="${timezone}" date +%Y%m%d%H%M)-${zip_name}" | sed 's|.zip||')
export hash=$(cat "$finalzip_path.sha256sum" | cut -d" " -f1)
export fullOta=$(cat "${finalzip_path}.json")
if [ "${buildsuccessful}" == "0" ] && [ ! -z "${finalzip_path}" ]; then
    echo "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"

    echo "Uploading $finalzip_path"

    github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

Hash: $hash
Date: $(env TZ="${timezone}" date)" "${finalzip_path}"

    github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

Hash: $hash
Date: $(env TZ="${timezone}" date)" "${finalzip_path}.sha256sum"
    github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

Hash: $hash
Date: $(env TZ="${timezone}" date)" "${finalzip_path}.json"
    if [ "${generate_incremental}" == "true" ]; then
        if [ -e "${incremental_zip_path}" ] && [ "${old_target_files_exists}" == "true" ]; then
            github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

Hash: $hash
Date: $(env TZ="${timezone}" date)" "${incremental_zip_path}"
        elif [ ! -e "${incremental_zip_path}" ] && [ "${old_target_files_exists}" == "true" ]; then
            echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
            telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
            [ ! -z "$TELEGRAM_TOKEN" ] && curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
            exit 1
        fi
    fi
    if [ "${upload_recovery}" == "true" ]; then
        if [ -e "${img_path}" ]; then
            github-release "${release_repo}" "${tag}" "master" "${ROM} for ${device}

Hash: $hash
Date: $(env TZ="${timezone}" date)" "${img_path}"
        else
            echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
            telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
            [ ! -z "$TELEGRAM_TOKEN" ] && curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
            exit 1
        fi
    fi
    echo "Uploaded"

    if [ "${upload_recovery}" == "true" ]; then
        if [ "${old_target_files_exists}" == "true" ]; then
            telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download ROM: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")
Download incremental update: ["incremental_ota_update.zip"]("https://github.com/${release_repo}/releases/download/${tag}/incremental_ota_update.zip")
Download recovery: ["recovery.img"]("https://github.com/${release_repo}/releases/download/${tag}/recovery.img")"
        else
            telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download ROM: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")
Download recovery: ["recovery.img"]("https://github.com/${release_repo}/releases/download/${tag}/recovery.img")"
        fi
    else
        if [ "${old_target_files_exists}" == "true" ]; then
            telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")
Download incremental update: ["incremental_ota_update.zip"]("https://github.com/${release_repo}/releases/download/${tag}/incremental_ota_update.zip")"
        else
            telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download: ["${zip_name}"]("https://github.com/${release_repo}/releases/download/${tag}/${zip_name}")"
        fi
    fi
[ ! -z "$TELEGRAM_TOKEN" ] && curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker

    if [ "${generate_incremental}" == "true" ]; then
        wget -O- --post-data '{"'"$hash"'": "'"https://github.com/${release_repo}/releases/download/${tag}/${zip_name}"'", "'"$hash.incr"'": "'"https://github.com/${release_repo}/releases/download/${tag}/incremental_ota_update.zip"'"}' "$PUSH_URL" >/dev/null 2>&1 || echo "-- BIGOTA PUSH FAIL --"
    else
        wget -O- --post-data '{"'"$hash"'": "'"https://github.com/${release_repo}/releases/download/${tag}/${zip_name}"'"}' "$PUSH_URL" >/dev/null 2>&1 || echo "-- BIGOTA PUSH FAIL --"
    fi
    if [ "${LINEAGE_BUILDTYPE}" == "RELEASE" ]; then
        if ! [ "${old_target_files_exists}" == "true" ]; then
            export incrOta="{}"
            export old_incr_ver=""
        fi
        wget -O- --post-data '{"secret": "'"$OTA_SECRET"'", "codename": "'"$device"'", "oldIncr": "'"$old_incr_ver"'", "fullOta": "'"$fullOta"'", "incrOta": "'"$incrOta"'"}' "$OTA_URL" >/dev/null 2>&1 || echo "-- OTA PUSH FAIL --"
    fi
    echo "Done"
else
    echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
    [ ! -z "$TELEGRAM_TOKEN" ] && curl --data parse_mode=HTML --data chat_id=$TELEGRAM_CHAT --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
    exit 1
fi
true
