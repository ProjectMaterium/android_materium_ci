#!/bin/bash

#export GITHUB_USER="kiam001"
#export GITHUB_EMAIL="blablatupfen@gmail.com"

#export device=""

export rom_branch=ng-v2
export ROM="droid-ng"
export ROM_DIR="${WORKSPACE}/rom"
export ROM_VERSION="v2.0 Alpha"
export official="true"
#export local_manifest_url=""
export manifest_url="https://github.com/droid-ng/android"
export rom_vendor_name="ng"
export branch="ng-v2"
export bacon="bacon" #"signed_bacon"
#export buildtype=""
# export clean="installclean" set via jenkins
export generate_incremental="true"
export upload_recovery="true"

export ccache="true"
export ccache_size="100G"

export jenkins="true"

export release_repo="droid-ng/android_ng_ci"

export timezone="Europe/Berlin"
