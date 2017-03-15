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

for TARGET in ${TARGETS}
do
  # Determine relevant SDK version
  if [[ "${TARGET}" == tvos* ]]; then
    SDKVERSION="${TVOS_SDKVERSION}"
  else
    SDKVERSION="${IOS_SDKVERSION}"
  fi

  # These variables are used in the configuration file
  export SDKVERSION
  export IOS_MIN_SDK_VERSION
  export TVOS_MIN_SDK_VERSION
  export CONFIG_DISABLE_BITCODE

  # Determine platform
  if [[ "${TARGET}" == "ios-sim-cross-"* ]]; then
    PLATFORM="iPhoneSimulator"
  elif [[ "${TARGET}" == "tvos-sim-cross-"* ]]; then
    PLATFORM="AppleTVSimulator"
  elif [[ "${TARGET}" == "tvos64-cross-"* ]]; then
    PLATFORM="AppleTVOS"
  else
    PLATFORM="iPhoneOS"
  fi

  # Extract ARCH from TARGET (part after last dash)
  ARCH=$(echo "${TARGET}" | sed -E 's|^.*\-([^\-]+)$|\1|g')

  # Cross compile references, see Configurations/10-main.conf
  export CROSS_COMPILE="${DEVELOPER}/Toolchains/XcodeDefault.xctoolchain/usr/bin/"
  export CROSS_TOP="${DEVELOPER}/Platforms/${PLATFORM}.platform/Developer"
  export CROSS_SDK="${PLATFORM}${SDKVERSION}.sdk"

  # Prepare TARGETDIR and SOURCEDIR
  prepare_target_source_dirs

  ## Determine config options
  # Add build target, --prefix and prevent async (references to getcontext(),
  # setcontext() and makecontext() result in App Store rejections) and creation
  # of shared libraries (default since 1.1.0)
  LOCAL_CONFIG_OPTIONS="${TARGET} --prefix=${TARGETDIR} ${CONFIG_OPTIONS} no-async no-shared"

  # Only relevant for 64 bit builds
  if [[ "${CONFIG_ENABLE_EC_NISTP_64_GCC_128}" == "true" && "${ARCH}" == *64  ]]; then
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} enable-ec_nistp_64_gcc_128"
  fi

  # Run Configure
  run_configure

  # Run make
  run_make

  # Run make install
  set -e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make install_dev | tee -a "${LOG}"
  else
    make install_dev >> "${LOG}" 2>&1
  fi

  # Remove source dir, add references to library files to relevant arrays
  # Keep reference to first build target for include file
  finish_build_loop
done
