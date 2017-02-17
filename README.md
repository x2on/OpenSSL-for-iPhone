# OpenSSL-for-iOS [![Build Status](https://travis-ci.org/x2on/OpenSSL-for-iPhone.svg)](https://travis-ci.org/x2on/OpenSSL-for-iPhone) [![license](https://img.shields.io/github/license/x2on/OpenSSL-for-iPhone.svg)](https://github.com/x2on/OpenSSL-for-iPhone/blob/master/LICENSE) [![OpenSSL version](https://img.shields.io/badge/OpenSSL-1.0.2k-lightgrey.svg)]() [![OpenSSL version](https://img.shields.io/badge/OpenSSL-1.1.0e-lightgrey.svg)]() [![iOS support](https://img.shields.io/badge/iOS-7.0%20--%2010.2-lightgrey.svg)]() [![tvOS support](https://img.shields.io/badge/tvOS-9.2--%2010.1-lightgrey.svg)]()

This is a script for using self-compiled builds of the OpenSSL-library on the iPhone. You can build apps with Xcode and the official SDK from Apple with this. I also made a small example-app for using the libraries with Xcode and the iPhone/iPhone-Simulator.

**Enjoy OpenSSL on the iPhone!**

You must build the OpenSSL-Libraries (1.0.2k) before running the sample with:
```bash
./build-libssl.sh
```

To build OpenSSL 1.1.0e build the OpenSSL-Libraries with:
```bash
./build-libssl.sh --version=1.1.0e
```

For all options see the help
```bash
./build-libssl.sh --help
```

This repository contains an iOS 10.0 Xcode Project which uses the OpenSSL Libraries. The examples uses the MD5 or SHA256-algorithm to calculate an md5 or sha256 hash from an UITextfield.

## System support
**iOS 7.0 - iOS 10.2 (i386, x86_64, armv7, armv7s, armv64, bitcode) and tvOS 9.2 - tvOS 10.1 (x86_64, arm64, bitcode) are currently supported.**

For iOS < 7.0 you must use Xcode < 7 and an older version of the build script.

If you have problems building for arm64 please uninstall MacPorts (see [#28](https://github.com/x2on/OpenSSL-for-iPhone/issues/28)).

## Original tutorials for this project:
* <http://www.x2on.de/2010/02/01/tutorial-iphone-app-with-compiled-openssl-library/>
* <http://www.x2on.de/2010/07/13/tutorial-iphone-app-with-compiled-openssl-1-0-0a-library/>

## Changelog
* 2017-02-16: OpenSSL 1.1.0e
* 2017-01-28: OpenSSL 1.0.2k, 1.1.0d, Xcode 8.2 (iOS 10.2 and tvOS 10.1)
* 2016-11-13: OpenSSL 1.1.0c
* 2016-11-07: Optional support for OpenSSL 1.1.0b
* 2016-09-28: OpenSSL 1.0.2j
* 2016-09-22: OpenSSL 1.0.2i
* 2016-09-18: Xcode 8 support, iOS 10.0, Add command line options, Optimize build
* 2016-08-09: Xcode 7.3 support, iOS 9.3
* 2016-05-04: OpenSSL 1.0.2h
* 2015-12-11: Xcode 7.2 support, iOS 9.2
* 2015-12-03: OpenSSL 1.0.2e
* 2015-11-17: tvOS example app, Migrate to Swift for example app
* 2015-11-16: tvOS support
* 2015-10-25: Xcode 7.1 support
* 2015-08-06: iOS 9.0 support, Bitcode support
* 2015-07-09: OpenSSL 1.0.2d, iOS 8.4
* 2015-06-15: OpenSSL 1.0.2c, iOS 8.3
* 2015-06-11: OpenSSL 1.0.2b
* 2015-03-19: OpenSSL 1.0.2a
* 2015-01-28: OpenSSL 1.0.2
* 2015-01-10: OpenSSL 1.0.1k
* 2014-10-15: OpenSSL 1.0.1j
* 2014-09-18: iOS 8.0 support
* 2014-08-08: OpenSSL 1.0.1i
* 2014-06-05: OpenSSL 1.0.1h
* 2014-04-07: OpenSSL 1.0.1g
* 2014-03-12: iOS 7.1 support
* 2014-01-07: OpenSSL 1.0.1f
* 2013-10-12: x86_64 support, Migrate project to iOS 7.0
* 2013-09-23: iOS 7.0 support
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
