#!/bin/bash
VERSION="1.1.1l"
TARGETS="ios-sim-cross-x86_64 ios-sim-cross-arm64 ios64-cross-arm64 ios64-cross-arm64e macos64-x86_64 macos64-arm64 mac-catalyst-x86_64 mac-catalyst-arm64"
FRAMEWORK="openssl.xcframework"
FRAMEWORK_ZIP="openssl.xcframework.zip"
FRAMEWORK_DIR="swiftpm/$VERSION"
./build-libssl.sh --version="$VERSION" --targets="$TARGETS"
./create-openssl-framework.sh dynamic
( cd frameworks && zip -yr $FRAMEWORK_ZIP $FRAMEWORK )
mkdir -p $FRAMEWORK_DIR
mv frameworks/$FRAMEWORK_ZIP $FRAMEWORK_DIR
swift package compute-checksum $FRAMEWORK_DIR/$FRAMEWORK_ZIP
