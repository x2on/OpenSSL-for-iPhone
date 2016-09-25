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

# Build 1.0.2 in current directory
./build-libssl.sh --noparallel --verbose-on-error | log_output "ARCHS  " &
PID_ARCHS=$!

# Build 1.1.0 in (temporary) subdirectory
mkdir targets
cd targets
../build-libssl.sh --noparallel --verbose-on-error --ec-nistp-64-gcc-128 --version=1.1.0a | log_output "TARGETS" &
PID_TARGETS=$!

echo "SCRIPT  Started jobs, waiting for jobs to finish"
wait ${PID_ARCHS}
wait ${PID_TARGETS}
