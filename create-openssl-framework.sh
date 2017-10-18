#!/bin/bash

set -eu
#set -euxo pipefail

if [ $# == 0 ]; then
    echo "Usage: `basename $0` static|dynamic"
    exit 1
fi

if [ ! -d lib ]; then
    echo "Please run build-libssl.sh first!"
    exit 1
fi

FWTYPE=$1
FWNAME=openssl
FWROOT=frameworks

if [ -d $FWROOT ]; then
    echo "Removing previous $FWNAME.framework copies"
    rm -rf $FWROOT
fi

ALL_SYSTEMS=("iPhone" "AppleTV")

function check_bitcode() {
    local FWDIR=$1

    if [[ $FWTYPE == static ]]; then
        BITCODE_PATTERN="__bitcode"
    else
        BITCODE_PATTERN="__LLVM"
    fi

    if otool -l "$FWDIR/$FWNAME" | grep -q "${BITCODE_PATTERN}"; then
    #BITCODE_MATCHES=$(otool -l "$FWDIR/$FWNAME" | grep -c "${BITCODE_PATTERN}")
    #if [[ $BITCODE_MATCHES -gt 0 ]]; then
        echo "INFO: $FWDIR contains Bitcode"
    else
        echo "INFO: $FWDIR doesn't contain Bitcode"
    fi
}

if [ $FWTYPE == "dynamic" ]; then
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

        echo "Assembling .dylib for $PLATFORM $SDKVERSION ($ARCH)"

        CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
        CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
        SDK="${CROSS_TOP}/SDKs/${CROSS_SDK}"

        if [[ $PLATFORM == "AppleTV"* ]]; then
            MIN_SDK="-tvos_version_min 9.0"
        else
            MIN_SDK="-ios_version_min 8.0"
        fi

        #cd $TARGETDIR
        #libtool -dynamic -lSystem $MIN_SDK -syslibroot $SDK -install_name $INSTALL_NAME -compatibility_version $COMPAT_VERSION -current_version $CURRENT_VERSION lib/*.a -o $FWNAME.dylib

        TARGETOBJ="${TARGETDIR}/obj"
        rm -rf $TARGETOBJ
        mkdir $TARGETOBJ
        cd $TARGETOBJ
        ar -x ../lib/libcrypto.a
        ar -x ../lib/libssl.a
        cd ..

        ld obj/*.o \
            -dylib \
            -bitcode_bundle \
            -lSystem \
            -arch $ARCH \
            $MIN_SDK \
            -syslibroot $SDK \
            -compatibility_version $COMPAT_VERSION \
            -current_version $CURRENT_VERSION \
            -application_extension \
            -o $FWNAME.dylib
        install_name_tool -id $INSTALL_NAME $FWNAME.dylib

        cd ..
    done
    cd ..

    for SYS in ${ALL_SYSTEMS[@]}; do
        SYSDIR="$FWROOT/$SYS"
        FWDIR="$SYSDIR/$FWNAME.framework"
        DYLIBS=(bin/${SYS}*/$FWNAME.dylib)

        if [[ ${#DYLIBS[@]} -gt 0 && -e ${DYLIBS[0]} ]]; then
            echo "Creating framework for $SYS"
            mkdir -p $FWDIR/Headers
            lipo -create ${DYLIBS[@]} -output $FWDIR/$FWNAME
            cp -r include/$FWNAME/* $FWDIR/Headers/
            cp -L assets/$SYS/Info.plist $FWDIR/Info.plist
            echo "Created $FWDIR"
            check_bitcode $FWDIR
        else
            echo "Skipped framework for $SYS"
        fi
    done

    rm bin/*/$FWNAME.dylib
else
    for SYS in ${ALL_SYSTEMS[@]}; do
        SYSDIR="$FWROOT/$SYS"
        FWDIR="$SYSDIR/$FWNAME.framework"

        if [[ -e lib/libcrypto-$SYS.a && -e lib/libssl-$SYS.a ]]; then
            echo "Creating framework for $SYS"
            mkdir -p $FWDIR/Headers
            libtool -static -o $FWDIR/$FWNAME lib/libcrypto-$SYS.a lib/libssl-$SYS.a
            cp -r include/$FWNAME/* $FWDIR/Headers/
            cp -L assets/$SYS/Info.plist $FWDIR/Info.plist
            echo "Created $FWDIR"
            check_bitcode $FWDIR
        else
            echo "Skipped framework for $SYS"
        fi
    done
fi
