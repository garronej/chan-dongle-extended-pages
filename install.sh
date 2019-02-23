#!/bin/bash

# TODO: Test if debian or ubuntu distribution comply to requirements.

INSTALL_PATH=/usr/share/dongle
TARBALL_PATH=/tmp/dongle.tar.gz

if [[ $EUID -ne 0 ]]; then
    echo "This script require root privileges."
    exit 1
fi

if [ -d "$INSTALL_PATH" ]; then

    echo "Directory $INSTALL_PATH already exsist, uninstalling previous install"
    
    dongle_uninstaller run 2>/dev/null
    
    rm -rf $INSTALL_PATH

fi

RELEASES_INDEX=$(wget -qO- https://github.com/garronej/releases/releases/download/chan-dongle-extended/index.json)

VERSION=$(echo $RELEASES_INDEX | grep -Po "\"$(uname -m)\": *\K\"[^\"]*\"")

DL_URL=$(echo $RELEASES_INDEX | grep -Po "$VERSION: *\K\"[^\"]*\"" | sed 's/^"\(.*\)"$/\1/')

wget $DL_URL -q --show-progress -O $TARBALL_PATH

mkdir $INSTALL_PATH

printf "Extracting"

tar -xzf $TARBALL_PATH -C $INSTALL_PATH --checkpoint=.100

rm $TARBALL_PATH

cd $INSTALL_PATH && ./node dist/bin/installer install
