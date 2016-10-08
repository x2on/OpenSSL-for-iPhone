#!/bin/sh

FWNAME=openssl

if [ ! -d lib ]; then
    echo "Please run build-libssl.sh first!"
    exit 1
fi

if [ -d $FWNAME.framework ]; then
    echo "Removing previous $FWNAME.framework copy"
    rm -rf $FWNAME.framework
fi

if [ "$1" == "dynamic" ]; then
    LIBTOOL_FLAGS="-dynamic -undefined dynamic_lookup -ios_version_min 8.0"
else
    LIBTOOL_FLAGS="-static"
fi

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers
libtool -no_warning_for_no_symbols $LIBTOOL_FLAGS -o $FWNAME.framework/$FWNAME lib/libcrypto.a lib/libssl.a
cp -r include/$FWNAME/* $FWNAME.framework/Headers/

DIR="$(cd "$(dirname "$0")" && pwd)"
cp $DIR/"OpenSSL-for-iOS/OpenSSL-for-iOS-Info.plist" $FWNAME.framework/Info.plist
echo "Created $FWNAME.framework"

check_bitcode=`otool -arch arm64 -l $FWNAME.framework/$FWNAME | grep __bitcode`
if [ -z "$check_bitcode" ]
then
  echo "INFO: $FWNAME.framework doesn't contain Bitcode"
else
  echo "INFO: $FWNAME.framework contains Bitcode"
fi
