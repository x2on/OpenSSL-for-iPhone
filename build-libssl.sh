#!/bin/sh

#  Automatic build script for libssl and libcrypto
#  for iPhoneOS and iPhoneSimulator
#
#  Created by Felix Schulze on 16.12.10.
#  Copyright 2010-2016 Felix Schulze. All rights reserved.
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
#  Change values here                                                     #
#                                                                         #
VERSION="1.0.2h"                                                          #
IOS_SDKVERSION=`xcrun -sdk iphoneos --show-sdk-version`                   #
TVOS_SDKVERSION=`xcrun -sdk appletvos --show-sdk-version`                 #
CONFIG_OPTIONS=""                                                         #
CURL_OPTIONS=""                                                           #

# To set "enable-ec_nistp_64_gcc_128" configuration for x64 archs set next variable to "true"
ENABLE_EC_NISTP_64_GCC_128=""                                             #
#                                                                         #
###########################################################################
#                                                                         #
# Don't change anything under this line!                                  #
#                                                                         #
###########################################################################
spinner()
{
  local pid=$!
  local delay=0.75
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf " [%c]" "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b"
  done
  printf "    \b\b"

  wait $pid
  return $?
}

# Check for error status
check_status()
{
  local STATUS=$1
  local COMMAND=$2

  echo "\n"
  if [ "${STATUS}" != 0 ]; then
    if [[ "${LOG_VERBOSE}" != "verbose"* ]]; then
      echo "Problem during ${COMMAND} - Please check ${LOG}"
    fi

    # Dump last 500 lines from log file for verbose-on-error
    if [ "${LOG_VERBOSE}" == "verbose-on-error" ]; then
      echo "Problem during ${COMMAND} - Dumping last 500 lines from log file"
      echo
      tail -n 500 "${LOG}"
    fi

    exit 1
  fi
}

CURRENTPATH=`pwd`
ARCHS="x86_64 i386 arm64 armv7s armv7 tv_x86_64 tv_arm64"
DEVELOPER=`xcode-select -print-path`
IOS_MIN_SDK_VERSION="7.0"
TVOS_MIN_SDK_VERSION="9.0"
LOG_VERBOSE="$1" # Options: verbose (full output) or verbose-on-error (echo last 500 logged lines when error occurs)

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

# -e  Abort script at first error, when a command exits with non-zero status (except in until or while loops, if-tests, list constructs)
# -o pipefail  Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero return value
set -eo pipefail

# Download OpenSSL when not present
OPENSSL_ARCHIVE_BASE_NAME=OpenSSL_${VERSION//./_}
OPENSSL_ARCHIVE_FILE_NAME=${OPENSSL_ARCHIVE_BASE_NAME}.tar.gz
if [ ! -e ${OPENSSL_ARCHIVE_FILE_NAME} ]; then
  echo "Downloading ${OPENSSL_ARCHIVE_FILE_NAME}"
  curl ${CURL_OPTIONS} -L -O https://github.com/openssl/openssl/archive/${OPENSSL_ARCHIVE_FILE_NAME}
else
  echo "Using ${OPENSSL_ARCHIVE_FILE_NAME}"
fi

mkdir -p "${CURRENTPATH}/src"
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"

# Init vars for library references
INCLUDE_DIR=""
LIBSSL_IOS=()
LIBCRYPTO_IOS=()
LIBSSL_TVOS=()
LIBCRYPTO_TVOS=()

for ARCH in ${ARCHS}
do
  if [[ "$ARCH" == tv* ]]; then
    SDKVERSION=$TVOS_SDKVERSION
    MIN_SDK_VERSION=$TVOS_MIN_SDK_VERSION
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
    PLATFORM="AppleTVOS"
  else
    PLATFORM="iPhoneOS"
  fi

  export $PLATFORM
  export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
  export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
  export BUILD_TOOLS="${DEVELOPER}"

  # Prepare target dir
  TARGETDIR="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
  mkdir -p "${TARGETDIR}"
  LOG="${TARGETDIR}/build-openssl-${VERSION}.log"

  echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}..."
  echo "  Logfile: ${LOG}"


  LOCAL_CONFIG_OPTIONS="${CONFIG_OPTIONS}"
  if [ "${ENABLE_EC_NISTP_64_GCC_128}" == "true" ]; then
    case "$ARCH" in
      *64*)
        LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} enable-ec_nistp_64_gcc_128"
      ;;
    esac
  fi

  if [[ $SDKVERSION == 9.* || $SDKVERSION == [0-9][0-9].* ]]; then
    export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH} -fembed-bitcode"
  else
    export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"
  fi

  echo "  Patch source code..."

  src_work_dir="${CURRENTPATH}/src/${PLATFORM}-${ARCH}"
  mkdir -p "$src_work_dir"
  tar zxf "${CURRENTPATH}/${OPENSSL_ARCHIVE_FILE_NAME}" -C "$src_work_dir"
  cd "${src_work_dir}/openssl-${OPENSSL_ARCHIVE_BASE_NAME}"

  chmod u+x ./Configure
  if [[ "${PLATFORM}" == "AppleTVSimulator" || "${PLATFORM}" == "AppleTVOS" ]]; then
    LC_ALL=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"
    LC_ALL=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"

    if [[ "${ARCH}" == "arm64" ]]; then
      sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    fi
  elif [[ "$PLATFORM" == "iPhoneOS" ]]; then
    sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
  fi

  # Run Configure
  echo "  Configure...\c"
  set +e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    if [ "${ARCH}" == "x86_64" ]; then
      ./Configure no-asm darwin64-x86_64-cc --openssldir="${TARGETDIR}" ${LOCAL_CONFIG_OPTIONS} | tee "${LOG}"
    else
      ./Configure iphoneos-cross --openssldir="${TARGETDIR}" ${LOCAL_CONFIG_OPTIONS} | tee "${LOG}"
    fi
  else
    if [ "${ARCH}" == "x86_64" ]; then
      (./Configure no-asm darwin64-x86_64-cc --openssldir="${TARGETDIR}" ${LOCAL_CONFIG_OPTIONS} > "${LOG}" 2>&1) & spinner
    else
      (./Configure iphoneos-cross --openssldir="${TARGETDIR}" ${LOCAL_CONFIG_OPTIONS} > "${LOG}" 2>&1) & spinner
    fi
  fi
  
  # Check for error status
  check_status $? "Configure"

  echo "  Patch Makefile..."
  # add -isysroot to CC=
  if [[ "${PLATFORM}" == "AppleTVSimulator" || "${PLATFORM}" == "AppleTVOS" ]]; then
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
  else
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${MIN_SDK_VERSION} !" "Makefile"
  fi

  # Run make depend if relevant
  if [[ ! -z "${CONFIG_OPTIONS}" ]]; then
    echo "  Make depend...\c"
    if [ "${LOG_VERBOSE}" == "verbose" ]; then
      make depend | tee -a "${LOG}"
    else
      (make depend >> "${LOG}" 2>&1) & spinner
    fi

    # Check for error status
    check_status $? "make depend"
  fi

  # Run make
  echo "  Make...\c"
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make | tee -a "${LOG}"
  else
    (make >> "${LOG}" 2>&1) & spinner
  fi

  # Check for error status
  check_status $? "make"

  # Run make install
  set -e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make install_sw | tee -a "${LOG}"
  else
    make install_sw >> "${LOG}" 2>&1
  fi

  # Remove source dir
  rm -rf "$src_work_dir"

  # Add references to library files to relevant arrays
  if [[ "${PLATFORM}" == AppleTV* ]]; then
    LIBSSL_TVOS+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_TVOS+=("${TARGETDIR}/lib/libcrypto.a")
  else
    LIBSSL_IOS+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_IOS+=("${TARGETDIR}/lib/libcrypto.a")
  fi

  # Keep reference to first build target for include file
  if [ -z "${INCLUDE_DIR}" ]; then
    INCLUDE_DIR="${TARGETDIR}/include/openssl"
  fi
done

# Build iOS library if selected for build
if [ ${#LIBSSL_IOS} -gt 0 ]; then
  echo "Build library for iOS..."
  lipo -create ${LIBSSL_IOS[@]} -output "${CURRENTPATH}/lib/libssl.a"
  lipo -create ${LIBCRYPTO_IOS[@]} -output "${CURRENTPATH}/lib/libcrypto.a"
fi

# Build tvOS library if selected for build
if [ ${#LIBSSL_TVOS} -gt 0 ] ; then
    echo "Build library for tvOS..."
    lipo -create ${LIBSSL_TVOS[@]} -output "${CURRENTPATH}/lib/libssl-tvOS.a"
    lipo -create ${LIBCRYPTO_TVOS[@]} -output "${CURRENTPATH}/lib/libcrypto-tvOS.a"
fi

# Copy include directory
cp -R "${INCLUDE_DIR}" ${CURRENTPATH}/include/

echo "Done."
