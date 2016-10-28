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

DEFAULTVERSION="1.0.2j" # Default version in case no version is specified
IOS_MIN_SDK_VERSION="7.0" # Minimum iOS SDK version to build for
TVOS_MIN_SDK_VERSION="9.0" # Minimum tvOS SDK version to build for

# Init optional env variables
CURL_OPTIONS="${CURL_OPTIONS:-}"
CONFIG_OPTIONS="${CONFIG_OPTIONS:-}"

echo_help()
{
  echo "Usage: $0 [options...]"
  echo "     --archs=\"ARCH ARCH ...\"       Space-separated list of architectures to build"
  echo "                                     Options: x86_64 i386 arm64 armv7s armv7 tv_x86_64 tv_arm64"
  echo "                                     Note: The framework will contain include files from the architecture listed first"
  echo "     --branch=BRANCH               Select OpenSSL branch to build. The script will determine and download the latest release for that branch"
  echo "                                     Note: This script does not yet work with OpenSSL 1.1.0"
  echo "     --cleanup                     Clean up build directories (bin, include/openssl, lib, src) before starting build"
  echo "     --ec-nistp-64-gcc-128         Enable config option enable-ec_nistp_64_gcc_128 for 64 bit builds"
  echo " -h, --help                        Print help (this message)"
  echo "     --ios-sdk=SDKVERSION          Override iOS SDK version"
  echo "     --noparallel                  Disable running make with parallel jobs (make -j)"
  echo "     --tvos-sdk=SDKVERSION         Override tvOS SDK version"
  echo " -v, --verbose                     Enable verbose logging"
  echo "     --verbose-on-error            Dump last 500 lines from log file if an error occurs (for Travis builds)"
  echo "     --version=VERSION             OpenSSL version to build (defaults to ${DEFAULTVERSION})"
  echo "                                     Note: This script does not yet work with OpenSSL 1.1.0"
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

# Init optional command line vars
ARCHS=""
BRANCH=""
CLEANUP=""
CONFIG_ENABLE_EC_NISTP_64_GCC_128=""
IOS_SDKVERSION=""
PARALLEL=""
LOG_VERBOSE=""
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

# Determine SDK versions
if [ ! -n "${IOS_SDKVERSION}" ]; then
  IOS_SDKVERSION=$(xcrun -sdk iphoneos --show-sdk-version)
fi
if [ ! -n "${TVOS_SDKVERSION}" ]; then
  TVOS_SDKVERSION=$(xcrun -sdk appletvos --show-sdk-version)
fi

# Set default for ARCHS if not specified
if [ ! -n "${ARCHS}" ]; then
  ARCHS="x86_64 i386 arm64 armv7s armv7 tv_x86_64 tv_arm64"
fi

# Determine number of cores for (parallel) build
BUILD_THREADS=1
if [ "${PARALLEL}" != "false" ]; then
  BUILD_THREADS=$(sysctl hw.ncpu | awk '{print $2}')
fi

# Write files relative to script location and validate directory
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
echo "  Architectures: ${ARCHS}"
echo "  iOS SDK: ${IOS_SDKVERSION}"
echo "  tvOS SDK: ${TVOS_SDKVERSION}"
echo "  Number of make threads: ${BUILD_THREADS}"
if [ -n "${CONFIG_OPTIONS}" ]; then
  echo "  Configure options: ${CONFIG_OPTIONS}"
fi
echo "  Script directory and build location: ${CURRENTPATH}"
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
  if [[ "${SDKVERSION}" == 9.* || "${SDKVERSION}" == [0-9][0-9].* ]]; then
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} -fembed-bitcode"
  fi

  # Add platform specific config options
  if [[ "${PLATFORM}" == AppleTV* ]]; then
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} -DHAVE_FORK=0 -mtvos-version-min=${TVOS_MIN_SDK_VERSION}"
    echo "  Patching Configure..."
    LC_ALL=C sed -i -- 's/D\_REENTRANT\:iOS/D\_REENTRANT\:tvOS/' "./Configure"
  else
    LOCAL_CONFIG_OPTIONS="${LOCAL_CONFIG_OPTIONS} -miphoneos-version-min=${IOS_MIN_SDK_VERSION}"
  fi

  if [ "${ARCH}" == "x86_64" ] ; then
    # make sure DES_LONG is set to unsigned long, also for the darwin64-x86_64 build, as otherwise opensslconf.h
    # will have a different value (unsigned int) for x86_64, whereas every iphoneos-cross build has unsigned long.
    # this would lead to various stack corruptions when using DES methods on devices.
    # enable RC4_CHAR, BN_LLONG and BF_PTR for the same reason
    LC_ALL=C sed -ie 's/^"darwin64-x86_64-cc"\(.*\)DES_INT\(.*\)/"darwin64-x86_64-cc"\1RC4_CHAR BN_LLONG BF_PTR\2/' "./Configure"
  fi

  # Add --openssldir option
  LOCAL_CONFIG_OPTIONS="--openssldir=${TARGETDIR} ${LOCAL_CONFIG_OPTIONS}"

  # Determine configure target
  if [ "${ARCH}" == "x86_64" ]; then
    LOCAL_CONFIG_OPTIONS="darwin64-x86_64-cc no-asm ${LOCAL_CONFIG_OPTIONS}"
  else
    LOCAL_CONFIG_OPTIONS="iphoneos-cross no-asm ${LOCAL_CONFIG_OPTIONS}"
  fi

  # Run Configure
  echo "  Configure...\c"
  set +e
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    ./Configure ${LOCAL_CONFIG_OPTIONS} | tee "${LOG}"
  else
    (./Configure ${LOCAL_CONFIG_OPTIONS} > "${LOG}" 2>&1) & spinner
  fi

  # Check for error status
  check_status $? "Configure"

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
  echo "  Make...\c"
  if [ "${LOG_VERBOSE}" == "verbose" ]; then
    make -j "${BUILD_THREADS}" | tee -a "${LOG}"
  else
    (make -j "${BUILD_THREADS}" >> "${LOG}" 2>&1) & spinner
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
  else
    # make sure the just-compiled version has a compatible opensslconf.h
    TEMP1=`mktemp`
    TEMP2=`mktemp`
    grep -v 'ENGINESDIR\|OPENSSLDIR\|SYSNAME\|SIXTY_FOUR_BIT_LONG\|THIRTY_TWO_BIT' ${INCLUDE_DIR}/opensslconf.h > $TEMP1
    grep -v 'ENGINESDIR\|OPENSSLDIR\|SYSNAME\|SIXTY_FOUR_BIT_LONG\|THIRTY_TWO_BIT' ${TARGETDIR}/include/openssl/opensslconf.h > $TEMP2
    if ! cmp $TEMP1 $TEMP2 > /dev/null ; then
      echo "opensslconf.h is different between platforms! this is bad!"
      diff -uN $TEMP1 $TEMP2;
      rm $TEMP1 $TEMP2;
      exit 1;
    fi
    rm $TEMP1 $TEMP2;
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
