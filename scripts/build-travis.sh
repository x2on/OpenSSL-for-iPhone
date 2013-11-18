#!/bin/sh

echo "Build"
xctool -project OpenSSL-for-iOS.xcodeproj -scheme OpenSSL-for-iOS -sdk iphonesimulator clean build