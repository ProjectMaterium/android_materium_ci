#!/bin/bash

export tag=$(echo "$(env TZ="$timezone" date +%Y%m%d%H%M)-$zip_name" | sed 's|.zip||')
echo "--- Uploading... ---"

github-release "$RELEASE_REPO" "$tag" "main" "$ROM for $DEVICE

Date: $(env TZ="$timezone" date)" "$finalzip_path*"
if [ "$generate_incremental" == "true" ]; then
    if [ -e "$incremental_zip_path" ] && [ "$old_target_files_exists" == "true" ]; then
        github-release "$RELEASE_REPO" "$tag" "main" "$ROM for $DEVICE

Date: $(env TZ="$timezone" date)" "$incremental_zip_path"
    elif [ ! -e "$incremental_zip_path" ] && [ "$old_target_files_exists" == "true" ]; then
        echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        telegram -N -M "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        curl --data parse_mode=HTML --data chat_id="$TELEGRAM_CHAT" --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot$TELEGRAM_TOKEN/sendSticker
        exit 1
    fi
fi
if [ "$upload_recovery" == "true" ]; then
    if [ -e "$img_path" ]; then
        github-release "$RELEASE_REPO" "$tag" "main" "$ROM for $DEVICE

Date: $(env TZ="$timezone" date)" "$img_path"
    else
        echo "Build failed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds"
        exit 1
    fi
fi
echo "--- Upload done ---"

if [ "$upload_recovery" == "true" ]; then
    if [ "$old_target_files_exists" == "true" ]; then
        telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download ROM: [$zip_name](\"https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name\")
Download incremental update: [incremental_ota_update.zip](\"https://github.com/$RELEASE_REPO/releases/download/$tag/incremental_ota_update.zip\")
Download recovery: [recovery.img](\"https://github.com/$RELEASE_REPO/releases/download/$tag/recovery.img\")"
        export FULL_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name"
        export INCREMENTAL_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/incremental_ota_update.zip"
        export RECOVERY_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/recovery.img"

    else
        telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download ROM: [$zip_name](\"https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name\")
Download recovery: [recovery.img](\"https://github.com/$RELEASE_REPO/releases/download/$tag/recovery.img\")"
        export FULL_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name"
        export RECOVERY_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/recovery.img"
    fi
else
    if [ "$old_target_files_exists" == "true" ]; then
        telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds

Download: [$zip_name](\"https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name\")
Download incremental update: [incremental_ota_update.zip](\"https://github.com/$RELEASE_REPO/releases/download/$tag/incremental_ota_update.zip\")"
        export FULL_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name"
        export INCREMENTAL_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/incremental_ota_update.zip"
    else
        telegram -M "Build completed successfully in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds
            
Download: [$zip_name](\"https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name\")"
        export FULL_DL_LINK="https://github.com/$RELEASE_REPO/releases/download/$tag/$zip_name"
    fi
fi
curl --data parse_mode=HTML --data chat_id="$TELEGRAM_CHAT" --data sticker=CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE --request POST https://api.telegram.org/bot"$TELEGRAM_TOKEN"/sendSticker
