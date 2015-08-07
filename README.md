# OpenSSL-for-iOS [![Build Status](https://travis-ci.org/x2on/OpenSSL-for-iPhone.png)](https://travis-ci.org/x2on/OpenSSL-for-iPhone)

This is a script for using self-compiled builds of the OpenSSL-library on the iPhone. You can build apps with XCode and the official SDK from Apple with this. I also made a small example-app for using the libraries with XCode and the iPhone/iPhone-Simulator.

**Enjoy OpenSSL on the iPhone!**

You must build the OpenSSL-Libraries before running the sample with:
```bash
./build-libssl.sh
```

This repository contains a iOS 9.0 XCode Project with usese the OpenSSL Libaries. The examples uses the MD5 or SHA256-algorithm to calculate an md5 or sha256 hash from an UITextfield.

## System support
**iOS 7.0 - iOS 9.0 (i386, x86_64, armv7, armv7s, armv64) is currently supported.**

For iOS < 7.0 you must use Xcode < 7 and an older version of the build script.

If you have problems building for arm64 please uninstall MacPorts (see #28).

## Original tutorials for this project:
* <http://www.x2on.de/2010/02/01/tutorial-iphone-app-with-compiled-openssl-library/>
* <http://www.x2on.de/2010/07/13/tutorial-iphone-app-with-compiled-openssl-1-0-0a-library/>

## Changelog
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
