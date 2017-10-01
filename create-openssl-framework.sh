#!/bin/bash

FWNAME=openssl

if [ ! -d lib ]; then
    echo "Please run build-libssl.sh first!"
    exit 1
fi

if [ -d $FWNAME.framework ]; then
    echo "Removing previous $FWNAME.framework copy"
    rm -rf $FWNAME.framework
fi

echo "Creating $FWNAME.framework"
mkdir -p $FWNAME.framework/Headers

if [ "$1" == "dynamic" ]; then
    DEVELOPER=`xcode-select -print-path`
    FW_EXEC_NAME="${FWNAME}.framework/${FWNAME}"
    INSTALL_NAME="@rpath/${FW_EXEC_NAME}"
    COMPAT_VERSION="1.0.0"
    CURRENT_VERSION="1.0.0"

    LIBTOOL_FLAGS="-dynamic -lSystem -ios_version_min 8.0"
    RX='([A-z]+)([0-9]+(\.[0-9]+)*)-([A-z0-9]+)\.sdk'

    cd bin
	for TARGETDIR in `ls -d *.sdk`; do
        if [[ $TARGETDIR =~ $RX ]]; then
            PLATFORM="${BASH_REMATCH[1]}"
            SDKVERSION="${BASH_REMATCH[2]}"
            ARCH="${BASH_REMATCH[4]}"
        fi

        echo "Assembling .dylib for $ARCH"

        CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
        CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
        SDK="${CROSS_TOP}/SDKs/${CROSS_SDK}"

        #cd $TARGETDIR
        #libtool $LIBTOOL_FLAGS -L"$SDK/usr/lib/" -install_name $INSTALL_NAME -compatibility_version $COMPAT_VERSION -current_version $CURRENT_VERSION lib/*.a -o $FWNAME.dylib

        TARGETOBJ="${TARGETDIR}/obj"
        rm -rf $TARGETOBJ
        mkdir $TARGETOBJ
        cd $TARGETOBJ
        ar -x ../lib/libcrypto.a
        ar -x ../lib/libssl.a
        cd ..
        ld obj/*.o -dylib -lSystem -ios_version_min 8.0 -L"$SDK/usr/lib/" -compatibility_version $COMPAT_VERSION -current_version $CURRENT_VERSION -application_extension -o $FWNAME.dylib
        install_name_tool -id $INSTALL_NAME $FWNAME.dylib

        cd ..
    done
    cd ..

    lipo -create bin/*/$FWNAME.dylib -output $FWNAME.framework/$FWNAME
    rm bin/*/$FWNAME.dylib
else
    LIBTOOL_FLAGS="-static"
    libtool $LIBTOOL_FLAGS -o $FWNAME.framework/$FWNAME lib/libcrypto.a lib/libssl.a
fi

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
