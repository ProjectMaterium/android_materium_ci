#!/bin/bash

export my_dir=$(pwd)
export PATH="$(pwd)/bin:${PATH}"

source "$my_dir"/config.sh

SYNC_START=$(date +"%s")
source "$my_dir"/sync.sh

SYNC_END=$(date +"%s")
SYNC_DIFF=$((SYNC_END - SYNC_START))
echo "--- Sync completed in $((SYNC_DIFF / 60)) minute(s) and $((SYNC_DIFF % 60)) seconds ---"

BUILD_START=$(date +"%s")
source "$my_dir"/build.sh
BUILD_END=$(date +"%s")
BUILD_DIFF=$((BUILD_END - BUILD_START))
echo "--- Build completed in $((BUILD_DIFF / 60)) minute(s) and $((BUILD_DIFF % 60)) seconds ---"

if [ "$PUSH_OTA" == "true" ]; then
    source "$my_dir"/ota.sh
fi

echo "--------------------------------"
echo "Done!"
echo "--------------------------------"