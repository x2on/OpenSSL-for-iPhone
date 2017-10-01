#!/bin/bash

FWNAME=openssl
FWDIR=frameworks

if [ ! -d lib ]; then
    echo "Please run build-libssl.sh first!"
    exit 1
fi

if [ -d $FWDIR ]; then
    echo "Removing previous $FWNAME.framework copies"
    rm -rf $FWDIR
fi

ALL_SYSTEMS=("iPhone" "AppleTV")

if [ "$1" == "dynamic" ]; then
    DEVELOPER=`xcode-select -print-path`
    FW_EXEC_NAME="${FWNAME}.framework/${FWNAME}"
    INSTALL_NAME="@rpath/${FW_EXEC_NAME}"
    COMPAT_VERSION="1.0.0"
    CURRENT_VERSION="1.0.0"

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

        if [[ $PLATFORM == AppleTV* ]]; then
            MIN_SDK="-tvos_version_min 9.0"
        else
            MIN_SDK="-ios_version_min 8.0"
        fi

        #cd $TARGETDIR
        #libtool -dynamic -lSystem $MIN_SDK -L"$SDK/usr/lib/" -install_name $INSTALL_NAME -compatibility_version $COMPAT_VERSION -current_version $CURRENT_VERSION lib/*.a -o $FWNAME.dylib

        TARGETOBJ="${TARGETDIR}/obj"
        rm -rf $TARGETOBJ
        mkdir $TARGETOBJ
        cd $TARGETOBJ
        ar -x ../lib/libcrypto.a
        ar -x ../lib/libssl.a
        cd ..
        ld obj/*.o -dylib -lSystem $MIN_SDK -L"$SDK/usr/lib/" -compatibility_version $COMPAT_VERSION -current_version $CURRENT_VERSION -application_extension -o $FWNAME.dylib
        install_name_tool -id $INSTALL_NAME $FWNAME.dylib

        cd ..
    done
    cd ..

    for SYS in ${ALL_SYSTEMS[@]}; do
        SYSDIR=$FWDIR/$SYS

        # FIXME: skip if no device objects

        echo "Creating framework for $SYS"
        mkdir -p $SYSDIR/$FWNAME.framework/Headers
        lipo -create bin/${SYS}*/$FWNAME.dylib -output $SYSDIR/$FWNAME.framework/$FWNAME
        cp -r include/$FWNAME/* $SYSDIR/$FWNAME.framework/Headers/
        cp -L assets/$SYS/Info.plist $SYSDIR/$FWNAME.framework/Info.plist
        echo "Created $SYSDIR/$FWNAME.framework"
    done

    rm bin/*/$FWNAME.dylib
else
    for SYS in ${ALL_SYSTEMS[@]}; do
        SYSDIR=$FWDIR/$SYS

        # FIXME: skip if no device objects

        echo "Creating framework for $SYS"
        mkdir -p $SYSDIR/$FWNAME.framework/Headers
        libtool -static -o $SYSDIR/$FWNAME.framework/$FWNAME lib/libcrypto-$SYS.a lib/libssl-$SYS.a
        cp -r include/$FWNAME/* $SYSDIR/$FWNAME.framework/Headers/
        cp -L assets/$SYS/Info.plist $SYSDIR/$FWNAME.framework/Info.plist
        echo "Created $SYSDIR/$FWNAME.framework"
    done
fi

check_bitcode=`otool -arch arm64 -l $FWDIR/iPhone/$FWNAME.framework/$FWNAME | grep __bitcode`
if [ -z "$check_bitcode" ]
then
  echo "INFO: $FWNAME.framework doesn't contain Bitcode"
else
  echo "INFO: $FWNAME.framework contains Bitcode"
fi
