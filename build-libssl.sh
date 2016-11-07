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

# -u  Attempt to use undefined variable outputs error message, and forces an exit
set -u

# SCRIPT DEFAULTS

# Default version in case no version is specified
DEFAULTVERSION="1.0.2j"

# Default (=full) set of architectures (OpenSSL <= 1.0.2) or targets (OpenSSL >= 1.1.0) to build
DEFAULTARCHS="x86_64 i386 arm64 armv7s armv7 tv_x86_64 tv_arm64"
DEFAULTTARGETS="ios-sim-cross-x86_64 ios-sim-cross-i386 ios64-cross-arm64 ios-cross-armv7s ios-cross-armv7 tvos-sim-cross-x86_64 tvos64-cross-arm64"

# Minimum iOS/tvOS SDK version to build for
IOS_MIN_SDK_VERSION="7.0"
TVOS_MIN_SDK_VERSION="9.0"

# Init optional env variables (use available variable or default to empty string)
CURL_OPTIONS="${CURL_OPTIONS:-}"
CONFIG_OPTIONS="${CONFIG_OPTIONS:-}"

echo_help()
{
  echo "Usage: $0 [options...]"
  echo "Generic options"
  echo "     --branch=BRANCH               Select OpenSSL branch to build. The script will determine and download the latest release for that branch"
  echo "     --cleanup                     Clean up build directories (bin, include/openssl, lib, src) before starting build"
  echo "     --ec-nistp-64-gcc-128         Enable configure option enable-ec_nistp_64_gcc_128 for 64 bit builds"
  echo " -h, --help                        Print help (this message)"
  echo "     --ios-sdk=SDKVERSION          Override iOS SDK version"
  echo "     --noparallel                  Disable running make with parallel jobs (make -j)"
  echo "     --tvos-sdk=SDKVERSION         Override tvOS SDK version"
  echo " -v, --verbose                     Enable verbose logging"
  echo "     --verbose-on-error            Dump last 500 lines from log file if an error occurs (for Travis builds)"
  echo "     --version=VERSION             OpenSSL version to build (defaults to ${DEFAULTVERSION})"
  echo
  echo "Options for OpenSSL 1.0.2 and lower ONLY"
  echo "     --archs=\"ARCH ARCH ...\"       Space-separated list of architectures to build"
  echo "                                     Options: ${DEFAULTARCHS}"
  echo "                                     Note: The framework will contain include files from the architecture listed first"
  echo
  echo "Options for OpenSSL 1.1.0 and higher ONLY"
  echo "     --deprecated                  Exclude no-deprecated configure option and build with deprecated methods"
  echo "     --targets=\"TARGET TARGET ...\" Space-separated list of build targets"
  echo "                                     Options: ${DEFAULTTARGETS}"
  echo "                                     Note: The library will use include files from the target listed first"
  echo
  echo "For custom configure options, set variable CONFIG_OPTIONS"
  echo "For custom cURL options, set variable CURL_OPTIONS"
  echo "  Example: CURL_OPTIONS=\"--proxy 192.168.1.1:8080\" ./build-libssl.sh"
}

spinner()
{
  local pid=$!
  local delay=0.75
  local spinstr='|/-\'
  while [ "$(ps a | awk '{print $1}' | grep $pid)" ]; do
    local temp=${spinstr#?}
    printf "  [%c]" "$spinstr"
    local spinstr=$temp${spinstr%"$temp"}
    sleep $delay
    printf "\b\b\b\b\b"
  done

  wait $pid
  return $?
}

# Prepare target and source dir in build loop
prepare_target_source_dirs()
{
  # Prepare target dir
  TARGETDIR="${CURRENTPATH}/bin/${PLATFORM}${SDKVERSION}-${ARCH}.sdk"
  mkdir -p "${TARGETDIR}"
  LOG="${TARGETDIR}/build-openssl-${VERSION}.log"

  echo "Building openssl-${VERSION} for ${PLATFORM} ${SDKVERSION} ${ARCH}..."
  echo "  Logfile: ${LOG}"

  # Prepare source dir
  SOURCEDIR="${CURRENTPATH}/src/${PLATFORM}-${ARCH}"
  mkdir -p "${SOURCEDIR}"
  tar zxf "${CURRENTPATH}/${OPENSSL_ARCHIVE_FILE_NAME}" -C "${SOURCEDIR}"
  cd "${SOURCEDIR}/openssl-${OPENSSL_ARCHIVE_BASE_NAME}"
  chmod u+x ./Configure
}

# Check for error status
check_status()
{
  local STATUS=$1
  local COMMAND=$2

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

# Run Configure in build loop
run_configure()
{
  echo "  Configure..."
  set +e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    ./Configure ${LOCAL_CONFIG_OPTIONS} | tee "${LOG}"
  else
    (./Configure ${LOCAL_CONFIG_OPTIONS} > "${LOG}" 2>&1) & spinner
  fi

  # Check for error status
  check_status $? "Configure"
}

# Run make in build loop
run_make()
{
  echo "  Make (using ${BUILD_THREADS} thread(s))..."
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make -j "${BUILD_THREADS}" | tee -a "${LOG}"
  else
    (make -j "${BUILD_THREADS}" >> "${LOG}" 2>&1) & spinner
  fi

  # Check for error status
  check_status $? "make"
}

# Cleanup and bookkeeping at end of build loop
finish_build_loop()
{
  # Return to ${CURRENTPATH} and remove source dir
  cd "${CURRENTPATH}"
  rm -r "${SOURCEDIR}"

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
}

# Init optional command line vars
ARCHS=""
BRANCH=""
CLEANUP=""
CONFIG_ENABLE_EC_NISTP_64_GCC_128=""
CONFIG_NO_DEPRECATED=""
IOS_SDKVERSION=""
LOG_VERBOSE=""
PARALLEL=""
TARGETS=""
TVOS_SDKVERSION=""
VERSION=""

# Process command line arguments
for i in "$@"
do
case $i in
  --archs=*)
    ARCHS="${i#*=}"
    shift
    ;;
  --branch=*)
    BRANCH="${i#*=}"
    shift
    ;;
  --cleanup)
    CLEANUP="true"
    ;;
  --deprecated)
    CONFIG_NO_DEPRECATED="false"
    ;;
  --ec-nistp-64-gcc-128)
    CONFIG_ENABLE_EC_NISTP_64_GCC_128="true"
    ;;
  -h|--help)
    echo_help
    exit
    ;;
  --ios-sdk=*)
    IOS_SDKVERSION="${i#*=}"
    shift
    ;;
  --noparallel)
    PARALLEL="false"
    ;;
  --targets=*)
    TARGETS="${i#*=}"
    shift
    ;;
  --tvos-sdk=*)
    TVOS_SDKVERSION="${i#*=}"
    shift
    ;;
  -v|--verbose)
    LOG_VERBOSE="verbose"
    ;;
  --verbose-on-error)
    LOG_VERBOSE="verbose-on-error"
    ;;
  --version=*)
    VERSION="${i#*=}"
    shift
    ;;
  *)
    echo "Unknown argument: ${i}"
    ;;
esac
done

# Don't mix version and branch
if [[ -n "${VERSION}" && -n "${BRANCH}" ]]; then
  echo "Either select a branch (the script will determine and build the latest version) or select a specific version, but not both."
  exit 1

# Specific version: Verify version number format. Expected: dot notation
elif [[ -n "${VERSION}" && ! "${VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+[a-z]*$ ]]; then
  echo "Unknown version number format. Examples: 1.0.2, 1.0.2h"
  exit 1

# Specific branch
elif [ -n "${BRANCH}" ]; then
  # Verify version number format. Expected: dot notation
  if [[ ! "${BRANCH}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "Unknown branch version number format. Examples: 1.0.2, 1.0.1"
    exit 1

  # Valid version number, determine latest version
  else
    echo "Checking latest version of ${BRANCH} branch on GitHub..."
    # Request all git tags for the openssl repostory, get all tags that match the current branch version (with an optional alphabetic suffix), remove everything except the version number, sort the list and get the last item
    GITHUB_VERSION=$(curl -Ls https://api.github.com/repos/openssl/openssl/git/refs/tags | grep -Eo "\"ref\": \"refs/tags/OpenSSL_${BRANCH//./_}[a-z]*\"" | sed -E 's|^.*"refs/tags/OpenSSL_([^"]+)".*$|\1|g' | sort | tail -1)

    # Verify result
    if [ -z "${GITHUB_VERSION}" ]; then
      echo "Could not determine latest version, please check https://github.com/openssl/openssl/releases and use --version option"
      exit 1
    fi

    VERSION="${GITHUB_VERSION//_/.}"

    # Check whether download exists
    # -I = HEAD, -L follow Location header, -f fail silently for 4xx errors and return status 22, -s silent
    curl ${CURL_OPTIONS} -ILfs "https://github.com/openssl/openssl/archive/OpenSSL_${GITHUB_VERSION}.tar.gz" > /dev/null

    # Check for success status
    if [ $? -ne 0 ]; then
      echo "Script determined latest version ${VERSION}, but the download archive does not seem to be available."
      echo "Please check https://github.com/openssl/openssl/releases and use --version option"
      exit 1
    fi
  fi

# Script default
elif [ -z "${VERSION}" ]; then
  VERSION="${DEFAULTVERSION}"
fi

# Set GITHUB_VERSION (version with underscores instead of dots)
GITHUB_VERSION="${VERSION//./_}"

# Build type:
# In short, type "archs" is used for OpenSSL versions in the 1.0 branch and type "targets" for later versions.
#
# Significant changes to the build process were introduced with OpenSSL 1.1.0. As a result, this script was updated
# to include two separate build loops for versions <= 1.0 and versions >= 1.1. The type "archs" matches the key variable
# used to determine for which platforms to build for the 1.0 branch. Since 1.1, all platforms are defined in a separate/
# custom configuration file as build targets. Therefore the key variable and type are called targets for 1.1 (and later).

# OpenSSL branches <= 1.0
if [[ "${GITHUB_VERSION}" =~ ^(0_9|1_0) ]]; then
  BUILD_TYPE="archs"

  # Set default for ARCHS if not specified
  if [ ! -n "${ARCHS}" ]; then
    ARCHS="${DEFAULTARCHS}"
  fi

# OpenSSL branches >= 1.1
else
  BUILD_TYPE="targets"

  # Set default for TARGETS if not specified
  if [ ! -n "${TARGETS}" ]; then
    TARGETS="${DEFAULTTARGETS}"
  fi

  # Add no-deprecated config option (if not overwritten)
  if [ "${CONFIG_NO_DEPRECATED}" != "false" ]; then
    CONFIG_OPTIONS="${CONFIG_OPTIONS} no-deprecated"
  fi
fi

# Determine SDK versions
if [ ! -n "${IOS_SDKVERSION}" ]; then
  IOS_SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version)
fi
if [ ! -n "${TVOS_SDKVERSION}" ]; then
  TVOS_SDKVERSION=$(xcrun -sdk appletvos --show-sdk-version)
fi

# Determine number of cores for (parallel) build
BUILD_THREADS=1
if [ "${PARALLEL}" != "false" ]; then
  BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')
fi

# Determine script directory
SCRIPTDIR=$(cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd)

# Write files relative to current location and validate directory
CURRENTPATH=$(pwd)
case "${CURRENTPATH}" in
  *\ * )
    echo "Your path contains whitespaces, which is not supported by 'make install'."
    exit 1
  ;;
esac
cd "${CURRENTPATH}"

# Validate Xcode Developer path
DEVELOPER=$(xcode-select -print-path)
if [ ! -d "${DEVELOPER}" ]; then
  echo "Xcode path is not set correctly ${DEVELOPER} does not exist"
  echo "run"
  echo "sudo xcode-select -switch <Xcode path>"
  echo "for default installation:"
  echo "sudo xcode-select -switch /Applications/Xcode.app/Contents/Developer"
  exit 1
fi

case "${DEVELOPER}" in
  *\ * )
    echo "Your Xcode path contains whitespaces, which is not supported."
    exit 1
  ;;
esac

# Show build options
echo
echo "Build options"
echo "  OpenSSL version: ${VERSION}"
if [ "${BUILD_TYPE}" == "archs" ]; then
  echo "  Architectures: ${ARCHS}"
else
  echo "  Targets: ${TARGETS}"
fi
echo "  iOS SDK: ${IOS_SDKVERSION}"
echo "  tvOS SDK: ${TVOS_SDKVERSION}"
echo "  Number of make threads: ${BUILD_THREADS}"
if [ -n "${CONFIG_OPTIONS}" ]; then
  echo "  Configure options: ${CONFIG_OPTIONS}"
fi
echo "  Build location: ${CURRENTPATH}"
echo

# Download OpenSSL when not present
OPENSSL_ARCHIVE_BASE_NAME=OpenSSL_${GITHUB_VERSION}
OPENSSL_ARCHIVE_FILE_NAME=${OPENSSL_ARCHIVE_BASE_NAME}.tar.gz
if [ ! -e ${OPENSSL_ARCHIVE_FILE_NAME} ]; then
  echo "Downloading ${OPENSSL_ARCHIVE_FILE_NAME}..."
  OPENSSL_ARCHIVE_URL="https://github.com/openssl/openssl/archive/${OPENSSL_ARCHIVE_FILE_NAME}"
  # -L follow Location header, -f fail silently for 4xx errors and return status 22, -O Use server-specified filename for download
  curl ${CURL_OPTIONS} -LfO "${OPENSSL_ARCHIVE_URL}"

  # Check for success status
  if [ $? -ne 0 ]; then
    echo "An error occured when trying to download OpenSSL ${VERSION} from ${OPENSSL_ARCHIVE_URL}."
    echo "Please check cURL's error message and/or your network connection."
    exit 1
  fi
else
  echo "Using ${OPENSSL_ARCHIVE_FILE_NAME}"
fi

# Set reference to custom configuration (OpenSSL 1.1.0)
# See: https://github.com/openssl/openssl/commit/afce395cba521e395e6eecdaf9589105f61e4411
export OPENSSL_LOCAL_CONFIG_DIR="${SCRIPTDIR}/config"

# -e  Abort script at first error, when a command exits with non-zero status (except in until or while loops, if-tests, list constructs)
# -o pipefail  Causes a pipeline to return the exit status of the last command in the pipe that returned a non-zero return value
set -eo pipefail

# Clean up target directories if requested and present
if [ "${CLEANUP}" == "true" ]; then
  if [ -d "${CURRENTPATH}/bin" ]; then
    rm -r "${CURRENTPATH}/bin"
  fi
  if [ -d "${CURRENTPATH}/include/openssl" ]; then
    rm -r "${CURRENTPATH}/include/openssl"
  fi
  if [ -d "${CURRENTPATH}/lib" ]; then
    rm -r "${CURRENTPATH}/lib"
  fi
  if [ -d "${CURRENTPATH}/src" ]; then
    rm -r "${CURRENTPATH}/src"
  fi
fi

# (Re-)create target directories
mkdir -p "${CURRENTPATH}/bin"
mkdir -p "${CURRENTPATH}/lib"
mkdir -p "${CURRENTPATH}/src"

# Init vars for library references
INCLUDE_DIR=""
LIBSSL_IOS=()
LIBCRYPTO_IOS=()
LIBSSL_TVOS=()
LIBCRYPTO_TVOS=()

# Run relevant build loop (archs = 1.0 style, targets = 1.1 style)
if [ "${BUILD_TYPE}" == "archs" ]; then
  source "${SCRIPTDIR}/scripts/build-loop-archs.sh"
else
  source "${SCRIPTDIR}/scripts/build-loop-targets.sh"
fi

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
