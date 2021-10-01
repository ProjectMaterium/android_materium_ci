#!/bin/bash

export GITHUB_USER="kiam001"
export GITHUB_EMAIL="blablatupen@gmail.com"

#export device=""

export ROM="Project Materium"
export ROM_DIR="${WORKSPACE}/materium"
export ROM_VERSION="v2.0 Alpha"
export official="true"
export local_manifest_url="https://github.com/ProjectMaterium/android/raw/$rom_branch/snippets/priv.xml"
export manifest_url="https://github.com/$FLAVOUR/android"
export rom_vendor_name="materium"
export branch="$rom_branch"
export bacon="bacon" #"signed_bacon"
#export buildtype=""
export clean="installclean"
export generate_incremental="false"
export upload_recovery="true"

export ccache="true"
export ccache_size="100G"

export jenkins="true"

export release_repo="ProjectMaterium/android_materium_ci"

export timezone="Europe/Berlin"
