# OpenSSL-for-iOS

From <http://www.x2on.de/2010/02/01/tutorial-iphone-app-with-compiled-openssl-library/> and <http://www.x2on.de/2010/07/13/tutorial-iphone-app-with-compiled-openssl-1-0-0a-library/>

## Overview
This is a tutorial (+script) for using self-compiled builds of the OpenSSL-library on the iPhone. You can build apps with XCode and the official SDK from Apple with this. I also made a small example-app for using the libraries with XCode and the iPhone/iPhone-Simulator.

**Enjoy OpenSSL on the iPhone!**

You must build the OpenSSL-Libraries before running the sample with:
```bash
./build-libssl.sh
```

This repository contains a iOS 6.1 XCode Project with usese the OpenSSL Libaries. The examples uses the MD5 or SHA256-algorithm to calculate an md5 or sha256 hash from an UITextfield.

## System support
**iOS 4.3 - iOS 6.0 (i386, armv7, armv7s) is currently supported.**

For iOS < 4.3 you must use iOS SDK < 6.0 and an older version of the build script.

## Changelog
* 2013-03-01: OpenSSL 1.0.1e, iOS 6.1
* 2012-09-21: Support for iOS 6.0 and iPhone 5 (armv7s) - Remove armv6 support
* 2012-05-17: OpenSSL 1.0.1c
* 2012-05-02: OpenSSL 1.0.1b
* 2012-04-01: OpenSSL 1.0.1, Modernizes project to use ARC
* 2012-01-28: OpenSSL 1.0.0g, Optimized build script
* 2011-10-23: OpenSSL 1.0.0e, iOS 5.0
* 2011-02-08: OpenSSL 1.0.0d
* 2010-12-16: Script for building OpenSSL
* 2010-12-04: SHA256 Hash, Clean project file with iOS 4.2 as base SDK
* 2010-12-04: OpenSSL 1.0.0c
* 2010-11-16: OpenSSL 1.0.0b
* 2010-06-30: OpenSSL 1.0.0a, iOS 4.0 as base SDK
* 2010-06-10: OpenSSL 0.9.8o, iPad Version
* 2010-03-31: OpenSSL 0.9.8n
* 2010-02-26: OpenSSL 0.9.8m
