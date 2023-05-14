#!/bin/bash

cd "$ROM_DIR" || exit 1

export outdir="$ROM_DIR/out/target/product/$DEVICE"

# --- setup ccache ---
if [ "$USE_CCACHE" == "true" ] && [ -n "$CCACHE_SIZE" ]; then
    ccache -M "$CCACHE_SIZE"
elif [ "$USE_CCACHE" == "true" ]; then
    ccache -M 50G
fi

source build/envsetup.sh
lunch ng_"$DEVICE"-"$BUILD_TYPE"

# --- clean up ---
if [ "$CLEAN_TYPE" == "clean" ]; then
    m clean -j"$(nproc --all)"
elif [ "$CLEAN_TYPE" == "installclean" ]; then
    m installclean -j"$(nproc --all)"
    rm -rf out/target/product/"${device}"/obj/DTBO_OBJ
else
    rm "$outdir"/*"$(date +%Y)"*.zip*
fi

# --- full build ---
m "$TARGET" -j"$(nproc --all)" | tee "$WORKSPACE"/build.log
if [ $? -eq 1 ]; then
    echo "--- Build failed ---"
    exit 1
fi

# --- incremental build ---
if [ "$BUILD_INCREMENTAL" == "true" ]; then
    [ -d "$TARGET_FILES_DIR" ] || mkdir "$TARGET_FILES_DIR"
    if [ -e "$TARGET_FILES_DIR"/*"$DEVICE"*target_files*.zip ]; then
        export old_target_files_exists=true
        export old_target_files_path=$(ls "$TARGET_FILES_DIR"/*"$DEVICE"*target_files*.zip | tail -n -1)
    else
        echo "--- Old target-files package not found, generating incremental package on next build ---"
    fi
    export new_target_files_path=$(ls "${outdir}"/obj/PACKAGING/target_files_intermediates/*target_files*.zip | tail -n -1)
    if [ "${old_target_files_exists}" == "true" ]; then
        ota_from_target_files -i "${old_target_files_path}" "${new_target_files_path}" "${outdir}"/incremental_ota_update.zip
        export incremental_zip_path=$(ls "${outdir}"/incremental_ota_update.zip | tail -n -1)
    fi
    cp "${new_target_files_path}" "${TARGET_FILES_DIR}"
fi

# --- setting file paths ---
if [ -e "${outdir}"/*$(date +%Y)*.zip ]; then
    export finalzip_path=$(ls "${outdir}"/*$(date +%Y)*.zip | tail -n -1)
else
    export finalzip_path=$(ls "${outdir}"/*"${device}"-ota-*.zip | tail -n -1)
fi
if [ "${upload_recovery}" == "true" ]; then
    if [ ! -e "${outdir}"/recovery.img ]; then
        cp "${outdir}"/boot.img "${outdir}"/recovery.img
    fi
    export img_path=$(ls "${outdir}"/recovery.img | tail -n -1)
fi