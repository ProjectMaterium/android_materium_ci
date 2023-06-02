#!/bin/bash

echo "Installing repo"
if [ ! "$USE_LOCAL_REPO" == "true" ]; then
    echo "--- Downloading repo ---"
    curl https://storage.googleapis.com/git-repo-downloads/repo > "$my_dir"/bin/repo
fi
chmod a+x "$my_dir"/bin/*

mkdir -p "$ROM_DIR"
cd "$ROM_DIR" || exit
rm -rf "$ROM_DIR"/.repo/local_manifests/roomservice.xml

echo "--- Initializing repo ---"
"$my_dir"/bin/repo init --git-lfs --submodules -v -u "$MANIFEST_URL" -b "$MANIFEST_BRANCH" --depth=1
if [ $? -eq 1 ]; then
    echo "Failed to initialize repo"
    exit 1
fi

echo "--- Syncing repo ---"
"$my_dir"/bin/repo sync --fail-fast --force-sync --no-prune --optimized-fetch --force-remove-dirty --fetch-submodules --no-auto-gc -c -v -n
if [ $? -eq 1 ]; then
    echo "Failed to sync repo"
    exit 1
fi

"$my_dir"/bin/repo sync --fail-fast --force-sync --prune --auto-gc --optimized-fetch --force-remove-dirty --fetch-submodules -c -v -l
if [ $? -eq 1 ]; then
    echo "Failed to checkout repo"
    exit 1
fi
