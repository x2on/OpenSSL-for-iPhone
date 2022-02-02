#!/bin/sh

#  Automatic build script for libssl and libcrypto
#  for Apple devices.
#
#  Created by Felix Schulze on 16.12.10.
#  Copyright 2010-2017 Felix Schulze. All rights reserved.
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
DEFAULTVERSION="1.1.1m"

# Default (=full) set of targets (OpenSSL >= 1.1.1) to build
DEFAULTTARGETS=`cat <<TARGETS
ios-sim-cross-x86_64 ios-sim-cross-arm64 ios64-cross-arm64 ios64-cross-arm64e
macos64-x86_64 macos64-arm64
mac-catalyst-x86_64 mac-catalyst-arm64
watchos-cross-armv7k watchos-cross-arm64_32 watchos-sim-cross-x86_64 watchos-sim-cross-i386 watchos-sim-cross-arm64
tvos-sim-cross-x86_64 tvos64-cross-arm64
TARGETS`

# Minimum iOS/tvOS SDK version to build for
IOS_MIN_SDK_VERSION="12.0"
MACOS_MIN_SDK_VERSION="10.14"
CATALYST_MIN_SDK_VERSION="10.14"
WATCHOS_MIN_SDK_VERSION="4.0"
TVOS_MIN_SDK_VERSION="12.0"

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
  echo "     --macos-sdk=SDKVERSION        Override macOS SDK version"
  echo "     --catalyst-sdk=SDKVERSION     Override macOS SDK version for Catalyst"
  echo "     --watchos-sdk=SDKVERSION      Override watchOS SDK version"
  echo "     --tvos-sdk=SDKVERSION         Override tvOS SDK version"
  echo "     --min-ios-sdk=SDKVERSION      Set minimum iOS SDK version (default: $IOS_MIN_SDK_VERSION)"
  echo "     --min-macos-sdk=SDKVERSION    Set minimum macOS SDK version (default: $MACOS_MIN_SDK_VERSION)"
  echo "     --min-watchos-sdk=SDKVERSION  Set minimum watchOS SDK version (default: $WATCHOS_MIN_SDK_VERSION)"
  echo "     --min-tvos-sdk=SDKVERSION     Set minimum tvOS SDK version (default: $TVOS_MIN_SDK_VERSION)"
  echo "     --noparallel                  Disable running make with parallel jobs (make -j)"
  echo "     --disable-bitcode             Disable embedding Bitcode"
  echo " -v, --verbose                     Enable verbose logging"
  echo "     --verbose-on-error            Dump last 500 lines from log file if an error occurs (for Travis builds)"
  echo "     --version=VERSION             OpenSSL version to build (defaults to ${DEFAULTVERSION})"
  echo "     --deprecated                  Exclude no-deprecated configure option and build with deprecated methods"
  echo "     --targets=\"TARGET TARGET ...\" Space-separated list of build targets"
  echo "                                     Options: ${DEFAULTTARGETS}"
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
  cd "${SOURCEDIR}/${OPENSSL_ARCHIVE_BASE_NAME}"
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
    ./Configure ${LOCAL_CONFIG_OPTIONS} no-tests | tee "${LOG}"
  else
    (./Configure ${LOCAL_CONFIG_OPTIONS} no-tests > "${LOG}" 2>&1) & spinner
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
  if [[ "${PLATFORM}" == iPhone* ]]; then
    LIBSSL_IOS+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_IOS+=("${TARGETDIR}/lib/libcrypto.a")
    if [[ "${PLATFORM}" == iPhoneSimulator* ]]; then
      OPENSSLCONF_SUFFIX="ios_sim_${ARCH}"
    else
      OPENSSLCONF_SUFFIX="ios_${ARCH}"
    fi
  elif [[ "${PLATFORM}" == Watch* ]]; then
    LIBSSL_WATCHOS+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_WATCHOS+=("${TARGETDIR}/lib/libcrypto.a")
    if [[ "${PLATFORM}" == WatchSimulator* ]]; then
      OPENSSLCONF_SUFFIX="watchos_sim_${ARCH}"
    else
      OPENSSLCONF_SUFFIX="watchos_${ARCH}"
    fi
  elif [[ "${PLATFORM}" == AppleTV* ]]; then
    LIBSSL_TVOS+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_TVOS+=("${TARGETDIR}/lib/libcrypto.a")
    if [[ "${PLATFORM}" == AppleTVSimulator* ]]; then
      OPENSSLCONF_SUFFIX="tvos_sim_${ARCH}"
    else
      OPENSSLCONF_SUFFIX="tvos_${ARCH}"
    fi
  elif [[ "${PLATFORM}" == Catalyst* ]]; then
    LIBSSL_CATALYST+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_CATALYST+=("${TARGETDIR}/lib/libcrypto.a")
    OPENSSLCONF_SUFFIX="catalyst_${ARCH}"
  else
    LIBSSL_MACOS+=("${TARGETDIR}/lib/libssl.a")
    LIBCRYPTO_MACOS+=("${TARGETDIR}/lib/libcrypto.a")
    OPENSSLCONF_SUFFIX="macos_${ARCH}"
  fi

  # Copy opensslconf.h to bin directory and add to array
  OPENSSLCONF="opensslconf_${OPENSSLCONF_SUFFIX}.h"
  cp "${TARGETDIR}/include/openssl/opensslconf.h" "${CURRENTPATH}/bin/${OPENSSLCONF}"
  OPENSSLCONF_ALL+=("${OPENSSLCONF}")

  # Keep reference to first build target for include file
  if [ -z "${INCLUDE_DIR}" ]; then
    INCLUDE_DIR="${TARGETDIR}/include/openssl"
  fi
}

gpg_validate()
{
  local TARGET=$1
  local SIG=${2:-${TARGET}.asc}

  GPG_B=$(which gpg)
  if [ ! -x "${GPG_B}" ]; then
    echo "WARN: No gpg executable found in PATH. Please consider installing gpg so archive signature validation can proceed."
    return 1
  fi

  $GPG_B --keyserver keys.openpgp.org --keyserver-options auto-key-retrieve,include-subkeys --verify-options show-photos --verify "${SIG}" "${TARGET}"
}

# Init optional command line vars
ARCHS=""
BRANCH=""
CLEANUP=""
CONFIG_ENABLE_EC_NISTP_64_GCC_128=""
CONFIG_DISABLE_BITCODE=""
CONFIG_NO_DEPRECATED=""
IOS_SDKVERSION=""
MACOS_SDKVERSION=""
CATALYST_SDKVERSION=""
WATCHOS_SDKVERSION=""
TVOS_SDKVERSION=""
LOG_VERBOSE=""
PARALLEL=""
TARGETS=""
VERSION=""

# Process command line arguments
for i in "$@"
do
case $i in
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
  --disable-bitcode)
   CONFIG_DISABLE_BITCODE="true"
   ;;
  -h|--help)
    echo_help
    exit
    ;;
  --ios-sdk=*)
    IOS_SDKVERSION="${i#*=}"
    shift
    ;;
  --macos-sdk=*)
    MACOS_SDKVERSION="${i#*=}"
    shift
    ;;
  --catalyst-sdk=*)
    CATALYST_SDKVERSION="${i#*=}"
    shift
    ;;
  --watchos-sdk=*)
    WATCHOS_SDKVERSION="${i#*=}"
    shift
    ;;
  --tvos-sdk=*)
    TVOS_SDKVERSION="${i#*=}"
    shift
    ;;
  --min-ios-sdk=*)
    IOS_MIN_SDK_VERSION="${i#*=}"
    shift
    ;;
  --min-macos-sdk=*)
    MACOS_MIN_SDK_VERSION="${i#*=}"
    shift
    ;;
  --min-watchos-sdk=*)
    WATCHOS_MIN_SDK_VERSION="${i#*=}"
    shift
    ;;
  --min-tvos-sdk=*)
    TVOS_MIN_SDK_VERSION="${i#*=}"
    shift
    ;;
  --noparallel)
    PARALLEL="false"
    ;;
  --targets=*)
    TARGETS="${i#*=}"
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
    echo "Unknown branch version number format. Examples: 1.0.2, 1.1.1"
    exit 1

  # Valid version number, determine latest version
  else
    echo "Checking latest version of ${BRANCH} branch on openssl.org..."
    # Get directory content listing of /source/ (only contains latest version per branch), limit list to archives (so one archive per branch),
    # filter for the requested branch, sort the list and get the last item (last two steps to ensure there is always 1 result)
    VERSION=$(curl ${CURL_OPTIONS} -s https://ftp.openssl.org/source/ | grep -Eo '>openssl-[0-9]\.[0-9]\.[0-9][a-z]*\.tar\.gz<' | grep -Eo "${BRANCH//./\.}[a-z]*" | sort | tail -1)

    # Verify result
    if [ -z "${VERSION}" ]; then
      echo "Could not determine latest version, please check https://www.openssl.org/source/ and use --version option"
      exit 1
    fi
  fi

# Script default
elif [ -z "${VERSION}" ]; then
  VERSION="${DEFAULTVERSION}"
fi

BUILD_TYPE="targets"

# Set default for TARGETS if not specified
if [ ! -n "${TARGETS}" ]; then
  TARGETS="${DEFAULTTARGETS}"
fi

# Add no-deprecated config option (if not overwritten)
if [ "${CONFIG_NO_DEPRECATED}" != "false" ]; then
  CONFIG_OPTIONS="${CONFIG_OPTIONS} no-deprecated"
fi

# Determine SDK versions
if [ ! -n "${IOS_SDKVERSION}" ]; then
  IOS_SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version)
fi
if [ ! -n "${MACOS_SDKVERSION}" ]; then
  MACOS_SDKVERSION=$(xcrun -sdk macosx --show-sdk-version)
fi
if [ ! -n "${CATALYST_SDKVERSION}" ]; then
  CATALYST_SDKVERSION=$(xcrun -sdk macosx --show-sdk-version)
fi
if [ ! -n "${WATCHOS_SDKVERSION}" ]; then
  WATCHOS_SDKVERSION=$(xcrun -sdk watchos --show-sdk-version)
fi
if [ ! -n "${TVOS_SDKVERSION}" ]; then
  TVOS_SDKVERSION=$(xcrun -sdk appletvos --show-sdk-version)
fi

# Truncate to minor version
MINOR_VERSION=(${MACOS_SDKVERSION//./ })
MACOS_SDKVERSION="${MINOR_VERSION[0]}.${MINOR_VERSION[1]}"
MINOR_VERSION=(${CATALYST_SDKVERSION//./ })
CATALYST_SDKVERSION="${MINOR_VERSION[0]}.${MINOR_VERSION[1]}"

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
echo "  Targets: ${TARGETS}"
echo "  iOS SDK: ${IOS_SDKVERSION} (min ${IOS_MIN_SDK_VERSION})"
echo "  macOS SDK: ${MACOS_SDKVERSION} (min ${MACOS_MIN_SDK_VERSION})"
echo "  macOS SDK (Catalyst): ${CATALYST_SDKVERSION} (min ${CATALYST_MIN_SDK_VERSION})"
echo "  watchOS SDK: ${WATCHOS_SDKVERSION} (min ${WATCHOS_MIN_SDK_VERSION})"
echo "  tvOS SDK: ${TVOS_SDKVERSION} (min ${TVOS_MIN_SDK_VERSION})"
if [ "${CONFIG_DISABLE_BITCODE}" == "true" ]; then
  echo "  Bitcode embedding disabled"
fi
echo "  Number of make threads: ${BUILD_THREADS}"
if [ -n "${CONFIG_OPTIONS}" ]; then
  echo "  Configure options: ${CONFIG_OPTIONS}"
fi
echo "  Build location: ${CURRENTPATH}"
echo

# Download OpenSSL when not present
OPENSSL_ARCHIVE_BASE_NAME="openssl-${VERSION}"
OPENSSL_ARCHIVE_FILE_NAME="${OPENSSL_ARCHIVE_BASE_NAME}.tar.gz"
OPENSSL_ARCHIVE_SIGNATURE_FILE_EXT=".asc"
OPENSSL_ARCHIVE_SIGNATURE_FILE_NAME="${OPENSSL_ARCHIVE_FILE_NAME}${OPENSSL_ARCHIVE_SIGNATURE_FILE_EXT}"
if [ ! -e ${OPENSSL_ARCHIVE_FILE_NAME} ]; then
  echo "Downloading ${OPENSSL_ARCHIVE_FILE_NAME}..."
  OPENSSL_ARCHIVE_BASE_URL="https://www.openssl.org/source"
  OPENSSL_ARCHIVE_URL="${OPENSSL_ARCHIVE_BASE_URL}/${OPENSSL_ARCHIVE_FILE_NAME}"

  # Check whether file exists here (this is the location of the latest version for each branch)
  # -s be silent, -f return non-zero exit status on failure, -I get header (do not download)
  curl ${CURL_OPTIONS} -sfI "${OPENSSL_ARCHIVE_URL}" > /dev/null

  # If unsuccessful, update the URL for older versions and try again.
  if [ $? -ne 0 ]; then
    BRANCH=$(echo "${VERSION}" | grep -Eo '^[0-9]\.[0-9]\.[0-9]')
    OPENSSL_ARCHIVE_URL="https://www.openssl.org/source/old/${BRANCH}/${OPENSSL_ARCHIVE_FILE_NAME}"

    curl ${CURL_OPTIONS} -sfI "${OPENSSL_ARCHIVE_URL}" > /dev/null
  fi

  # Both attempts failed, so report the error
  if [ $? -ne 0 ]; then
    echo "An error occurred trying to find OpenSSL ${VERSION} on ${OPENSSL_ARCHIVE_URL}"
    echo "Please verify that the version you are trying to build exists, check cURL's error message and/or your network connection."
    exit 1
  fi

  # Archive was found, so proceed with download.
  # -O Use server-specified filename for download
  curl ${CURL_OPTIONS} -O "${OPENSSL_ARCHIVE_URL}"
  # also download the gpg signature from the same location
  curl ${CURL_OPTIONS} -O "${OPENSSL_ARCHIVE_URL}${OPENSSL_ARCHIVE_SIGNATURE_FILE_EXT}"

else
  echo "Using ${OPENSSL_ARCHIVE_FILE_NAME}"
fi

# Validate archive signature
if [ -e ${OPENSSL_ARCHIVE_SIGNATURE_FILE_NAME} ]; then
  gpg_validate "${OPENSSL_ARCHIVE_FILE_NAME}" "${OPENSSL_ARCHIVE_SIGNATURE_FILE_NAME}"
  if [ $? -ne 0 ]; then
    echo "WARN: GPG signature validation was unsuccessful."
  fi
else
  echo "WARN: No GPG signature validation performed. (missing ${OPENSSL_ARCHIVE_SIGNATURE_FILE_NAME})"
fi

# Set reference to custom configuration (OpenSSL 1.1.1)
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
OPENSSLCONF_ALL=()
LIBSSL_IOS=()
LIBCRYPTO_IOS=()
LIBSSL_MACOS=()
LIBCRYPTO_MACOS=()
LIBSSL_CATALYST=()
LIBCRYPTO_CATALYST=()
LIBSSL_WATCHOS=()
LIBCRYPTO_WATCHOS=()
LIBSSL_TVOS=()
LIBCRYPTO_TVOS=()

source "${SCRIPTDIR}/scripts/build-loop-targets.sh"

# Copy include directory
cp -R "${INCLUDE_DIR}" "${CURRENTPATH}/include/"

# Only create intermediate file when building for multiple targets
# For a single target, opensslconf.h is still present in $INCLUDE_DIR (and has just been copied to the target include dir)
if [ ${#OPENSSLCONF_ALL[@]} -gt 1 ]; then

  # Prepare intermediate header file
  # This overwrites opensslconf.h that was copied from $INCLUDE_DIR
  OPENSSLCONF_INTERMEDIATE="${CURRENTPATH}/include/openssl/opensslconf.h"
  cp "${CURRENTPATH}/include/opensslconf-template.h" "${OPENSSLCONF_INTERMEDIATE}"

  # Loop all header files
  LOOPCOUNT=0
  for OPENSSLCONF_CURRENT in "${OPENSSLCONF_ALL[@]}" ; do

    # Copy specific opensslconf file to include dir
    cp "${CURRENTPATH}/bin/${OPENSSLCONF_CURRENT}" "${CURRENTPATH}/include/openssl"

    # Determine define condition
    case "${OPENSSLCONF_CURRENT}" in
      *_ios_arm64.h)
        DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64"
      ;;
      *_ios_arm64e.h)
        DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64E"
      ;;
      *_ios_sim_x86_64.h)
        DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_SIMULATOR && TARGET_CPU_X86_64"
      ;;
      *_ios_sim_arm64.h)
        DEFINE_CONDITION="TARGET_OS_IOS && TARGET_OS_SIMULATOR && TARGET_CPU_ARM64"
      ;;
      *_macos_x86_64.h)
        DEFINE_CONDITION="TARGET_OS_OSX && TARGET_CPU_X86_64"
      ;;
      *_macos_arm64.h)
        DEFINE_CONDITION="TARGET_OS_OSX && TARGET_CPU_ARM64"
      ;;
      *_catalyst_x86_64.h)
        DEFINE_CONDITION="(TARGET_OS_MACCATALYST || (TARGET_OS_IOS && TARGET_OS_SIMULATOR)) && TARGET_CPU_X86_64"
      ;;
      *_catalyst_arm64.h)
        DEFINE_CONDITION="(TARGET_OS_MACCATALYST || (TARGET_OS_IOS && TARGET_OS_SIMULATOR)) && TARGET_CPU_ARM64"
      ;;
      *_watchos_armv7k.h)
        DEFINE_CONDITION="TARGET_OS_WATCH && TARGET_OS_EMBEDDED && TARGET_CPU_ARM"
      ;;
      *_watchos_arm64_32.h)
        DEFINE_CONDITION="TARGET_OS_WATCH && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64"
      ;;
      *_watchos_sim_x86_64.h)
        DEFINE_CONDITION="TARGET_OS_WATCH && TARGET_OS_SIMULATOR && TARGET_CPU_X86_64"
      ;;
      *_watchos_sim_arm64.h)
        DEFINE_CONDITION="TARGET_OS_WATCH && TARGET_OS_SIMULATOR && TARGET_CPU_ARM64"
      ;;
      *_watchos_sim_i386.h)
        DEFINE_CONDITION="TARGET_OS_WATCH && TARGET_OS_SIMULATOR && TARGET_CPU_X86"
      ;;
      *_tvos_arm64.h)
        DEFINE_CONDITION="TARGET_OS_TV && TARGET_OS_EMBEDDED && TARGET_CPU_ARM64"
      ;;
      *_tvos_sim_x86_64.h)
        DEFINE_CONDITION="TARGET_OS_TV && TARGET_OS_SIMULATOR && TARGET_CPU_X86_64"
      ;;
      *)
        # Don't run into unexpected cases by setting the default condition to false
        DEFINE_CONDITION="0"
      ;;
    esac

    # Determine loopcount; start with if and continue with elif
    LOOPCOUNT=$((LOOPCOUNT + 1))
    if [ ${LOOPCOUNT} -eq 1 ]; then
      echo "#if ${DEFINE_CONDITION}" >> "${OPENSSLCONF_INTERMEDIATE}"
    else
      echo "#elif ${DEFINE_CONDITION}" >> "${OPENSSLCONF_INTERMEDIATE}"
    fi

    # Add include
    echo "# include <openssl/${OPENSSLCONF_CURRENT}>" >> "${OPENSSLCONF_INTERMEDIATE}"
  done

  # Finish
  echo "#else" >> "${OPENSSLCONF_INTERMEDIATE}"
  echo '# error Unable to determine target or target not included in OpenSSL build' >> "${OPENSSLCONF_INTERMEDIATE}"
  echo "#endif" >> "${OPENSSLCONF_INTERMEDIATE}"
fi

echo "Done."
