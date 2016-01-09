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
#  Change values here                                                     #
#                                                                         #
VERSION="1.0.2e"                                                          #
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
  while kill -0 $pid > /dev/null 2>&1; do
    local temp=${spinstr#?}
    printf " [%c]  " "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b\b"
  done
  printf "    \b\b\b\b"
}
dotting()
{
  local pid=$!
  local delay=1.00
  while kill -0 $pid > /dev/null 2>&1; do
    echo ".\c"
    sleep $delay
  done
}

exec_task()
{
  if [[ "$VERBOSE" != 0 ]]; then
    $1
  else
    $1 >> "${LOG}" 2>&1
  fi
}

exec_spinner_task()
{
  if [[ "$SPINNER_ENABLED" != 0 ]]; then
    (exec_task "$1") & spinner
  else
    (exec_task "$1") & dotting
  fi
}

CURRENTPATH=`pwd`
if [ "$ARCHS" == "" ]; then
  ARCHS="i386 x86_64 armv7 armv7s arm64 tv_x86_64 tv_arm64"
fi
DEVELOPER=`xcode-select -print-path`
IOS_MIN_SDK_VERSION="7.0"
TVOS_MIN_SDK_VERSION="9.0"

VERBOSE=0
SPINNER_ENABLED=1

while true ; do
  if [[ $# -lt 1 ]]; then
    break
  fi
  case "$1" in
    "verbose")
      VERBOSE=1
      shift
    ;;
    "--no-spinner")
      SPINNER_ENABLED=0
      shift
    ;;
    *)
      break
    ;;
  esac
done

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

iphone_out_dirs=""
tv_out_dirs=""

for ARCH in ${ARCHS}
do
  is_iphone_family=0
  is_tv_family=0

  if [[ "${ARCH}" == "i386" || "${ARCH}" == "x86_64" ]]; then
    PLATFORM="iPhoneSimulator"
    is_iphone_family=1
  elif [ "${ARCH}" == "tv_x86_64" ]; then
    ARCH="x86_64"
    PLATFORM="AppleTVSimulator"
    is_tv_family=1
  elif [ "${ARCH}" == "tv_arm64" ]; then
    ARCH="arm64"
    PLATFORM="AppleTVOS"
    is_tv_family=1
  else
    PLATFORM="iPhoneOS"
    is_iphone_family=1
  fi
  
  if [[ "$is_tv_family" != 0 ]]; then
    SDKVERSION=$TVOS_SDKVERSION
    MIN_SDK_VERSION=$TVOS_MIN_SDK_VERSION
  else
    SDKVERSION=$IOS_SDKVERSION
    MIN_SDK_VERSION=$IOS_MIN_SDK_VERSION
  fi

  export $PLATFORM
  export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
  export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
  export BUILD_TOOLS="${DEVELOPER}"

  output_dir="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"

  mkdir -p "$output_dir"
  LOG="$output_dir/build-openssl-${VERSION}.log"

  if [[ "$is_iphone_family" != 0 ]]; then
    iphone_out_dirs="$iphone_out_dirs $output_dir"
  elif [[ "$is_tv_family" != 0 ]]; then
    tv_out_dirs="$tv_out_dirs $output_dir"
  fi

  echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}"
  echo "  Logfile: $LOG"

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

  echo "  Patch source code..."

  src_work_dir="${CURRENTPATH}/src/${PLATFORM}-${ARCH}"
  mkdir -p "$src_work_dir"
  tar zxf "${CURRENTPATH}/openssl-${VERSION}.tar.gz" -C "$src_work_dir"
  cd "${src_work_dir}/openssl-${VERSION}"

  chmod u+x ./Configure
  if [[ "$is_tv_family" != 0 ]]; then
    LC_ALL=C sed -i -- 's/define HAVE_FORK 1/define HAVE_FORK 0/' "./apps/speed.c"
    LC_ALL=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"

    if [[ "${ARCH}" == "arm64" ]]; then
      sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
    fi
  elif [[ "$PLATFORM" == "iPhoneOS" ]]; then
    sed -ie "s!static volatile sig_atomic_t intr_signal;!static volatile intr_signal;!" "crypto/ui/ui_openssl.c"
  fi

  echo "  Configure...\c"
  set +e

  args=""
  if [ "${ARCH}" == "x86_64" ]; then
    args="${args} no-asm darwin64-x86_64-cc"
  else
    args="${args} iphoneos-cross"
  fi
  args="${args} \
    --openssldir=$output_dir \
    ${LOCAL_CONFIG_OPTIONS}"

  exec_spinner_task "./Configure ${args}"

  if [ $? != 0 ]; then
    echo "Problem while configure - Please check ${LOG}"
    exit 1
  fi

  echo "\n  Patch Makefile..."
  # add -isysroot to CC=
  if [[ "$is_tv_family" != 0 ]]; then
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -mtvos-version-min=${TVOS_MIN_SDK_VERSION} !" "Makefile"
  else
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} -miphoneos-version-min=${MIN_SDK_VERSION} !" "Makefile"
  fi

  echo "  Make...\c"

  if [[ ! -z $CONFIG_OPTIONS ]]; then
    exec_task "make depend"
  fi
  exec_spinner_task "make -j 4"

  echo "\n"

  if [ $? != 0 ]; then
    echo "Problem while make - Please check ${LOG}"
    exit 1
  fi

  set -e
  exec_task "make install_sw"
  exec_task "make clean"
  rm -rf "$src_work_dir"
done

if [[ "$iphone_out_dirs" != "" ]] ; then
  echo "Build library for iOS..."

  args=""
  for out_dir in $iphone_out_dirs; do
    args="$args ${out_dir}/lib/libssl.a"
  done
  lipo -create $args -output ${CURRENTPATH}/lib/libssl.a

  args=""
  for out_dir in $iphone_out_dirs; do
    args="$args ${out_dir}/lib/libcrypto.a"
  done
  lipo -create $args -output ${CURRENTPATH}/lib/libcrypto.a
fi

if [[ "$tv_out_dirs" != "" ]] ; then
  echo "Build library for tvOS..."

  args=""
  for out_dir in $tv_out_dirs; do
    args="$args ${out_dir}/lib/libssl.a"
  done
  lipo -create $args -output ${CURRENTPATH}/lib/libssl-tvOS.a

  args=""
  for out_dir in $tv_out_dirs; do
    args="$args ${out_dir}/lib/libcrypto.a"
  done
  lipo -create $args -output ${CURRENTPATH}/lib/libcrypto-tvOS.a
fi

mkdir -p ${CURRENTPATH}/include
for out_dir in $iphone_out_dirs $tv_out_dirs; do
  cp -R $out_dir/include/openssl ${CURRENTPATH}/include/
done

echo "Done."
