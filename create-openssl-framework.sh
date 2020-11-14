#!/bin/bash

set -euo pipefail

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

#ALL_SYSTEMS=("iPhone" "AppleTV" "MacOSX" "Catalyst" "Watch")
ALL_SYSTEMS=("iPhoneOS" "iPhoneSimulator" "AppleTVOS" "AppleTVSimulator" "MacOSX" "Catalyst" "WatchOS" "WatchSimulator")

function check_bitcode() {
    local FWDIR=$1

    if [[ $FWTYPE == "dynamic" ]]; then
        BITCODE_PATTERN="__LLVM"
    else
        BITCODE_PATTERN="__bitcode"
    fi

    if otool -l "$FWDIR/$FWNAME" | grep "${BITCODE_PATTERN}" >/dev/null; then
        echo "INFO: $FWDIR contains Bitcode"
    else
        echo "INFO: $FWDIR doesn't contain Bitcode"
    fi
}

# Inspect Mach-O load commands to get minimum SDK version.
#
# Depending on the actual minimum SDK version it may look like this
# (for modern SDKs):
#
#     Load command 1
#            cmd LC_BUILD_VERSION
#        cmdsize 24
#       platform 8
#            sdk 13.2                   <-- target SDK
#          minos 12.0                   <-- minimum SDK
#         ntools 0
#
# Or like this for older versions, with a platform-dependent tag:
#
#     Load command 1
#           cmd LC_VERSION_MIN_WATCHOS
#       cmdsize 16
#       version 4.0                     <-- minimum SDK
#           sdk 6.1                     <-- target SDK
function get_min_sdk() {
    local file=$1
    set +o pipefail
    otool -l "$file" | awk "
        /^Load command/ {
            last_command = \"\"
        }
        \$1 == \"cmd\" {
            last_command = \$2
        }
        (last_command ~ /LC_BUILD_VERSION/ && \$1 == \"minos\") ||
        (last_command ~ /^LC_VERSION_MIN_/ && \$1 == \"version\") {
            print \$2
            exit
        }
    "
    set -o pipefail
}

# Read OpenSSL version from opensslv.h file.
#
# In modern OpenSSL releases the version line looks like this:
#
#     # define OPENSSL_VERSION_TEXT    "OpenSSL 1.1.1g  21 Apr 2020"
#
# But for older versions with FIPS module it may look like this:
#
#     # ifdef OPENSSL_FIPS
#     #  define OPENSSL_VERSION_TEXT    "OpenSSL 1.0.2u-fips  20 Dec 2019"
#     # else
#     #  define OPENSSL_VERSION_TEXT    "OpenSSL 1.0.2u  20 Dec 2019"
#     # endif
#
# For App Store validation purposes, replace trailing letter with
# 2-digit offset from 'a' (ASCII 97), plus 1 for 1-based
#
#   1.0.2u
#   'u' = 117 -> 20 + 1 = 21
#   1.0.221
#
#   1.1.1g
#   'g' = 103 -> 6 + 1 = 07 (zero-padded)
#   1.1.107
#
function get_openssl_version() {
    local opensslv=$1
    local std_version=$(awk '/define OPENSSL_VERSION_TEXT/ && !/-fips/ {print $5}' "$opensslv")
    local generic_version=${std_version%?}
    local subpatch=${std_version: -1}
    local subpatch_number=$(($(printf '%d' \'$subpatch) - 97 + 1))
    local normalized_version="${generic_version}$(printf '%02d' $subpatch_number)"
    echo $normalized_version
}

if [ $FWTYPE == "dynamic" ]; then
    DEVELOPER=`xcode-select -print-path`
    FW_EXEC_NAME="${FWNAME}.framework/${FWNAME}"
    INSTALL_NAME="@rpath/${FW_EXEC_NAME}"
    COMPAT_VERSION="1.0.0"
    CURRENT_VERSION="1.0.0"

    RX='([A-z]+)([0-9]+(\.[0-9]+)*)-([A-z0-9_]+)\.sdk'

    cd bin
    for TARGETDIR in `ls -d *.sdk`; do
        if [[ $TARGETDIR =~ $RX ]]; then
            PLATFORM="${BASH_REMATCH[1]}"
            SDKVERSION="${BASH_REMATCH[2]}"
            ARCH="${BASH_REMATCH[4]}"
        fi

        echo "Assembling .dylib for $PLATFORM $SDKVERSION ($ARCH)"

        MIN_SDK_VERSION=$(get_min_sdk "${TARGETDIR}/lib/libcrypto.a")
        if [[ $PLATFORM == AppleTVSimulator* ]]; then
            MIN_SDK="-tvos_simulator_version_min $MIN_SDK_VERSION"
        elif [[ $PLATFORM == AppleTV* ]]; then
            MIN_SDK="-tvos_version_min $MIN_SDK_VERSION"
        elif [[ $PLATFORM == MacOSX* ]]; then
            MIN_SDK="-macosx_version_min $MIN_SDK_VERSION"
        elif [[ $PLATFORM == Catalyst* ]]; then
            MIN_SDK="-platform_version mac-catalyst 13.0 $MIN_SDK_VERSION"
            PLATFORM="MacOSX"
        elif [[ $PLATFORM == iPhoneSimulator* ]]; then
            MIN_SDK="-ios_simulator_version_min $MIN_SDK_VERSION"
        elif [[ $PLATFORM == WatchOS* ]]; then
            MIN_SDK="-watchos_version_min $MIN_SDK_VERSION"
        elif [[ $PLATFORM == WatchSimulator* ]]; then
            MIN_SDK="-watchos_simulator_version_min $MIN_SDK_VERSION"
        else
            MIN_SDK="-ios_version_min $MIN_SDK_VERSION"
        fi

        CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
        CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
        SDK="${CROSS_TOP}/SDKs/${CROSS_SDK}"

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
            MIN_SDK_VERSION=$(get_min_sdk "$FWDIR/$FWNAME")
            OPENSSL_VERSION=$(get_openssl_version "$FWDIR/Headers/opensslv.h")
            sed -e "s/\\\$(MIN_SDK_VERSION)/$MIN_SDK_VERSION/g" \
                -e "s/\\\$(OPENSSL_VERSION)/$OPENSSL_VERSION/g" \
                -i '' "$FWDIR/Info.plist"
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
        LIBS_CRYPTO=(bin/${SYS}*/lib/libcrypto.a)
        LIBS_SSL=(bin/${SYS}*/lib/libssl.a)

        if [[ ${#LIBS_CRYPTO[@]} -gt 0 && -e ${LIBS_CRYPTO[0]} && ${#LIBS_SSL[@]} -gt 0 && -e ${LIBS_SSL[0]} ]]; then
            echo "Creating framework for $SYS"
            mkdir -p $FWDIR/lib
            lipo -create ${LIBS_CRYPTO[@]} -output $FWDIR/lib/libcrypto.a
            lipo -create ${LIBS_SSL[@]} -output $FWDIR/lib/libssl.a
            libtool -static -o $FWDIR/$FWNAME $FWDIR/lib/*.a
            rm -rf $FWDIR/lib
            mkdir -p $FWDIR/Headers
            cp -r include/$FWNAME/* $FWDIR/Headers/
            cp -L assets/$SYS/Info.plist $FWDIR/Info.plist
            MIN_SDK_VERSION=$(get_min_sdk "$FWDIR/$FWNAME")
            OPENSSL_VERSION=$(get_openssl_version "$FWDIR/Headers/opensslv.h")
            sed -e "s/\\\$(MIN_SDK_VERSION)/$MIN_SDK_VERSION/g" \
                -e "s/\\\$(OPENSSL_VERSION)/$OPENSSL_VERSION/g" \
                -i '' "$FWDIR/Info.plist"
            echo "Created $FWDIR"
            check_bitcode $FWDIR
        else
            echo "Skipped framework for $SYS"
        fi
    done
fi

# macOS symlinks
for SYS in ${ALL_SYSTEMS[@]}; do
    if [[ $SYS == "MacOSX" ]]; then
        SYSDIR="$FWROOT/$SYS"
        FWDIR="$SYSDIR/$FWNAME.framework"
        if [[ ! -e "$FWDIR" ]]; then
            continue
        fi
        cd $FWDIR

        mkdir "Versions"
        mkdir "Versions/A"
        mkdir "Versions/A/Resources"
        mv "openssl" "Headers" "Versions/A"
        mv "Info.plist" "Versions/A/Resources"

        (cd "Versions" && ln -s "A" "Current")
        ln -s "Versions/Current/openssl"
        ln -s "Versions/Current/Headers"
        ln -s "Versions/Current/Resources"

        cd ../../..
    fi
done

build_xcframework() {
    local FRAMEWORKS=($FWROOT/*/$FWNAME.framework)
    local ARGS=
    for ARG in ${FRAMEWORKS[@]}; do
        ARGS+="-framework ${ARG} "
    done

    echo
    xcodebuild -create-xcframework $ARGS -output "$FWROOT/$FWNAME.xcframework"

    # These intermediate frameworks are silly, and not needed any more.
    #find ${FWROOT} -mindepth 1 -maxdepth 1 -type d -not -name "$FWNAME.xcframework" -exec rm -rf '{}' \;
}

build_xcframework
