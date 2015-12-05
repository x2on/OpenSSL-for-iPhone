#!/bin/sh

#  Automatic build script for libssl and libcrypto
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 16.12.10.
#  Copyright 2010-2015 Felix Schulze. All rights reserved.
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
#
VERSION="1.0.2e"													      #
IOS_SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`
TVOS_SDKVERSION=`xcrun -sdk appletvos --show-sdk-version`											  #
CONFIG_OPTIONS=""
CURL_OPTIONS=""

# To set "enable-ec_nistp_64_gcc_128" configuration for x64 archs set next variable to "true"
ENABLE_EC_NISTP_64_GCC_128=""
#																		  #
###########################################################################
#																		  #
# Don't change anything under this line!								  #
#																		  #
###########################################################################


CURRENTPATH=`pwd`
ARCHS="i386 x86_64 armv7 armv7s arm64 tv_x86_64 tv_arm64"
DEVELOPER=`xcode-select -print-path`
IOS_MIN_SDK_VERSION="7.0"
TVOS_MIN_SDK_VERSION="9.0"

if [ ! -d "$DEVELOPER" ]; then
  echo "xcode path is not set correctly $DEVELOPER does not exist"
  echo "run"
  echo "sudo xcode-select -switch <xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case $DEVELOPER in
     *\ * )
           echo "Your Xcode path contains whitespaces, which is not supported."
           exit 1
          ;;
esac

case $CURRENTPATH in
     *\ * )
           echo "Your path contains whitespaces, which is not supported by 'make install'."
           exit 1
          ;;
esac

set -e
if [ ! -e openssl-${VERSION}.tar.gz ]; then
	echo "Downloading openssl-${VERSION}.tar.gz"
    curl ${CURL_OPTIONS} -O https://www.openssl.org/source/openssl-${VERSION}.tar.gz
else
	echo "Using openssl-${VERSION}.tar.gz"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

tar zxf openssl-${VERSION}.tar.gz -C "${CURRENTPATH}/src"
cd "${CURRENTPATH}/src/openssl-${VERSION}"


for ARCH in ${ARCHS}
do
  if [[ "$ARCH" == tv* ]]; then
    SDKVERSION=$TVOS_SDKVERSION
    MIN_SDK_VERSION=$TVOS_MIN_SDK_VERSION
    LC_ALL=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"
    LC_ALL=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
    chmod u+x ./Configure
  else
    SDKVERSION=$IOS_SDKVERSION
    MIN_SDK_VERSION=$IOS_MIN_SDK_VERSION
  fi

	if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
		PLATFORM="iPhoneSimulator"
  elif [ "${ARCH}" == "tv_x86_64" ]; then
    ARCH="x86_64"
    PLATFORM="AppleTVSimulator"
  elif [ "${ARCH}" == "tv_arm64" ]; then
    ARCH="arm64"
    sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    PLATFORM="AppleTVOS"
	else
		sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    PLATFORM="iPhoneOS"
	fi

  export $PLATFORM
	export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
	export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
	export BUILD_TOOLS="${DEVELOPER}"

	echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
	echo "Please stand by..."

	LOCAL_CONFIG_OPTIONS="${CONFIG_OPTIONS}"
	if [ "${ENABLE_EC_NISTP_64_GCC_128}" == "true" ]; then
		case "$ARCH" in
			*64*)
				LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} enable-ec_nistp_64_gcc_128"
			;;
		esac
	fi

	if [[ $SDKVERSION == 9.* ]]; then
		export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH} -fembed-bitcode"
	else
		export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
	fi

	mkdir -p "${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
	LOG="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk/build-openssl-${VERSION}.log"

	set +e
	if [ "${ARCH}" == "x86_64" ]; then
	    ./Configure no-asm darwin64-x86_64-cc --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" ${LOCAL_CONFIG_OPTIONS} > "${LOG}" 2>&1
    	else
	    ./Configure iphoneos-cross --openssldir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk" ${LOCAL_CONFIG_OPTIONS} > "${LOG}" 2>&1
	fi

  if [ $? != 0 ]; then
    echo "Problem while configure - Please check ${LOG}"
    exit 1
  fi

  # add -isysroot to CC=
  if [[ "${PLATFORM}" == "AppleTVSimulator" || "${PLATFORM}" == "AppleTVOS" ]]; then
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
  else
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${MIN_SDK_VERSION} !" "Makefile"
  fi

	if [ "$1" == "verbose" ]; then
		if [[ ! -z $CONFIG_OPTIONS ]]; then
			make depend
		fi
		make
	else
		if [[ ! -z $CONFIG_OPTIONS ]]; then
			make depend >> "${LOG}" 2>&1
		fi
		make >> "${LOG}" 2>&1
	fi

	if [ $? != 0 ]; then
    echo "Problem while make - Please check ${LOG}"
    exit 1
  fi

  set -e
	make install_sw >> "${LOG}" 2>&1
	make clean >> "${LOG}" 2>&1
done

echo "Build library for iOS..."
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDKVERSION}-i386.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDKVERSION}-x86_64.sdk/lib/libssl.a  ${CURRENTPATH}/bin/iPhoneOS${IOS_SDKVERSION}-armv7.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDKVERSION}-armv7s.sdk/lib/libssl.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDKVERSION}-arm64.sdk/lib/libssl.a -output ${CURRENTPATH}/lib/libssl.a
lipo -create ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDKVERSION}-i386.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDKVERSION}-x86_64.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDKVERSION}-armv7.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDKVERSION}-armv7s.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/iPhoneOS${IOS_SDKVERSION}-arm64.sdk/lib/libcrypto.a -output ${CURRENTPATH}/lib/libcrypto.a

echo "Build library for tvOS..."
lipo -create ${CURRENTPATH}/bin/AppleTVSimulator${TVOS_SDKVERSION}-x86_64.sdk/lib/libssl.a ${CURRENTPATH}/bin/AppleTVOS${TVOS_SDKVERSION}-arm64.sdk/lib/libssl.a -output ${CURRENTPATH}/lib/libssl-tvOS.a
lipo -create ${CURRENTPATH}/bin/AppleTVSimulator${TVOS_SDKVERSION}-x86_64.sdk/lib/libcrypto.a ${CURRENTPATH}/bin/AppleTVOS${TVOS_SDKVERSION}-arm64.sdk/lib/libcrypto.a -output ${CURRENTPATH}/lib/libcrypto-tvOS.a

mkdir -p ${CURRENTPATH}/include
cp -R ${CURRENTPATH}/bin/iPhoneSimulator${IOS_SDKVERSION}-i386.sdk/include/openssl ${CURRENTPATH}/include/
echo "Building done."
echo "Cleaning up..."
rm -rf ${CURRENTPATH}/src/openssl-${VERSION}
echo "Done."
