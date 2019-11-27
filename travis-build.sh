#!/bin/sh

# Log script output with prefix
log_output()
{
  while read INPUT; do
    echo "${1} ${INPUT}"
  done
}

# Shut up curl
export CURL_OPTIONS="-s"

# Build in current directory
./build-libssl.sh --verbose-on-error | log_output "TARGETS  " &
PID_TARGETS=$!

echo "SCRIPT  Started jobs, waiting for jobs to finish"
wait ${PID_TARGETS}

xcrun -sdk iphoneos lipo -info ./lib/*.a | log_output "TARGETS  "
./create-openssl-framework.sh | log_output "TARGETS  "
xcrun -sdk iphoneos lipo -info openssl.framework/openssl | log_output "TARGETS  "

