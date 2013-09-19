#!/bin/sh

#  Automatic build script for libssl and libcrypto
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 16.12.10.
#  Copyright 2010 Felix Schulze. All rights reserved.
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.
#
###########################################################################
#  Change values here													  #
#																		  #
VERSION="1.0.1e"													      #
SDKVERSION="7.0"														  #
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################


CURRENTPATH=`pwd`

ARCHS="armv7 armv7s arm64"

DEVELOPER=`xcode-select -print-path`

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist (most likely because of xcode > 4.3)"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

set -e
if [ ! -e openssl-${VERSION}.tar.gz ]; then
	echo "Downloading openssl-${VERSION}.tar.gz"
    curl -O http://www.openssl.org/source/openssl-${VERSION}.tar.gz
else
	echo "Using openssl-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

tar zxf openssl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/openssl-${VERSION}"

LIPO_SSL_FAT_LIB="lipo -create"
LIPO_CRYPTO_FAT_LIB="lipo -create"

for ARCH in ${ARCHS}
do
	if [ "${ARCH}" == "i386" ];
	then
		PLATFORM="iPhoneSimulator"
	else
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
		PLATFORM="iPhoneOS"
	fi

	export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"

    if [ "${SDKVERSION}" == "7.0" ]; then
        export BUILD_TOOLS="${DEVELOPER}"
    else
        export BUILD_TOOLS="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
    fi

    export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."

	export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

    if [[ "$VERSION" =~ 1.0.0. ]]; then
	    ./Configure BSD-generic32 --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
    else
	    ./Configure iphoneos-cross --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" > "${LOG}" 2>&1
    fi

    if [ "${SDKVERSION}" == "7.0" ];
    then
        sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/Platforms/${PLATFORM}.platform/Developer/SDKs/${CROSS_SDK} !" "Makefile"
    fi

    if [ "${ARCH}" == "i386" ];
    then
        LIPO_SSL_FAT_LIB="${LIPO_SSL_FAT_LIB} ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-${ARCH}.sdk/lib/libssl.a"
        LIPO_CRYPTO_FAT_LIB="${LIPO_CRYPTO_FAT_LIB} ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-${ARCH}.sdk/lib/libcrypto.a"
    else
        LIPO_SSL_FAT_LIB="${LIPO_SSL_FAT_LIB} ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-${ARCH}.sdk/lib/libssl.a"
        LIPO_CRYPTO_FAT_LIB="${LIPO_CRYPTO_FAT_LIB} ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-${ARCH}.sdk/lib/libcrypto.a"
    fi

	make >> "${LOG}" 2>&1
	make install >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1

done

echo "Build library..."

LIPO_SSL_FAT_LIB="${LIPO_SSL_FAT_LIB} -output ${CURRENTPATH}/lib/libssl.a"
LIPO_CRYPTO_FAT_LIB="${LIPO_CRYPTO_FAT_LIB} -output ${CURRENTPATH}/lib/libcrypto.a"

eval $LIPO_SSL_FAT_LIB
eval $LIPO_CRYPTO_FAT_LIB

mkdir -p ${CURRENTPATH}/include

for ARCH in ${ARCHS}
do
    if [ -e ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-${ARCH}.sdk/include/openssl ];
    then
        cp -R ${CURRENTPATH}/bin/iPhoneSimulator${SDKVERSION}-${ARCH}.sdk/include/openssl ${CURRENTPATH}/include/
        break
    else
        if [ -e ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-${ARCH}.sdk/include/openssl ];
        then
            cp -R ${CURRENTPATH}/bin/iPhoneOS${SDKVERSION}-${ARCH}.sdk/include/openssl ${CURRENTPATH}/include/
            break
        fi
    fi
done
echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src/openssl-${VERSION}
echo "Done."
