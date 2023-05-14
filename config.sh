#!/bin/bash
# jenkins variables:
# DEVICE (device codename)
# CLEAN_TYPE (clean, installclean, or false)
# TARGET (e.g. bacon, otapackage, updatepackage, ...)
# BUILD_TYPE (user, userdebug, or eng)
# RELEASE_TYPE
# BUILD_INCREMENTAL (true or false)
# PUSH_OTA (true or false)

export USE_LOCAL_REPO="true"
export ROM_DIR="$WORKSPACE"/rom
export TARGET_FILES_DIR="$WORKSPACE"/target_files

export USE_CCACHE="true"
export CCACHE_DIR="$WORKSPACE"/ccache
export CCACHE_SIZE="200G"

export RELEASE_REPO="droid-ng/android_droid-ng_ci"

export MANIFEST_URL="https://github.com/droid-ng/android.git"
export MANIFEST_BRANCH="ng-v4"