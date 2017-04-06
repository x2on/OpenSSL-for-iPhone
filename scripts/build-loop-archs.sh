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

for ARCH in ${ARCHS}
do
  # Determine relevant SDK version
  if [[ "$ARCH" == tv* ]]; then
    SDKVERSION=${TVOS_SDKVERSION}
  else
    SDKVERSION=${IOS_SDKVERSION}
  fi

  # Determine platform, override arch for tvOS builds
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

  # Set env vars for Configure
  export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
  export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"
  export BUILD_TOOLS="${DEVELOPER}"
  export CC="${BUILD_TOOLS}/usr/bin/gcc -arch ${ARCH}"

  # Prepare TARGETDIR and SOURCEDIR
  prepare_target_source_dirs

  # Add optional enable-ec_nistp_64_gcc_128 configure option for 64 bit builds
  LOCAL_CONFIG_OPTIONS="${CONFIG_OPTIONS}"
  if [ "${CONFIG_ENABLE_EC_NISTP_64_GCC_128}" == "true" ]; then
    case "${ARCH}" in
      *64*)
        LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} enable-ec_nistp_64_gcc_128"
      ;;
    esac
  fi

  # Embed bitcode for SDK >= 9
  if [ "${CONFIG_DISABLE_BITCODE}" != "true" ]; then
    if [[ "${SDKVERSION}" == 9.* || "${SDKVERSION}" == [0-9][0-9].* ]]; then
      LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} -fembed-bitcode"
    fi
  fi

  # Add platform specific config options
  if [[ "${PLATFORM}" == AppleTV* ]]; then
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} -DHAVE_FORK=0 -mtvos-version-min=${TVOS_MIN_SDK_VERSION}"
    echo "  Patching Configure..."
    LC_ALL=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
  else
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} -miphoneos-version-min=${IOS_MIN_SDK_VERSION}"
  fi

  # Add --openssldir option
  LOCAL_CONFIG_OPTIONS="--openssldir=${TARGETDIR} ${LOCAL_CONFIG_OPTIONS}"

  # Determine configure target
  if [ "${ARCH}" == "x86_64" ]; then
    LOCAL_CONFIG_OPTIONS="darwin64-x86_64-cc no-asm ${LOCAL_CONFIG_OPTIONS}"
  else
    LOCAL_CONFIG_OPTIONS="iphoneos-cross ${LOCAL_CONFIG_OPTIONS}"
  fi

  # Run Configure
  run_configure

  # Only required for Darwin64 builds (-isysroot is automatically added by iphoneos-cross target)
  if [ "${ARCH}" == "x86_64" ]; then
    echo "  Patching Makefile..."
    sed -ie "s!^CFLAG=!CFLAG=-isysroot ${CROSS_TOP}/SDKs/${CROSS_SDK} !" "Makefile"
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
  run_make

  # Run make install
  set -e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make install_sw | tee -a "${LOG}"
  else
    make install_sw >> "${LOG}" 2>&1
  fi

  # Remove source dir, add references to library files to relevant arrays
  # Keep reference to first build target for include file
  finish_build_loop
done
