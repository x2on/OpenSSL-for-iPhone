# OpenSSL-Apple

[![license](https://img.shields.io/github/license/x2on/OpenSSL-for-iPhone.svg)](https://github.com/x2on/OpenSSL-for-iPhone/blob/master/LICENSE) [![OpenSSL version](https://img.shields.io/badge/OpenSSL-1.0.2l-lightgrey.svg)]() [![OpenSSL version](https://img.shields.io/badge/OpenSSL-1.1.0f-lightgrey.svg)]() [![iOS support](https://img.shields.io/badge/iOS-8%20--%2011-lightgrey.svg)]() [![tvOS support](https://img.shields.io/badge/tvOS-9%20--%2011-lightgrey.svg)]() [![macOS support](https://img.shields.io/badge/macOS-10.11%20--%2010.13-lightgrey.svg)]()

This is a fork of the popular work by [Felix Schulze](https://github.com/x2on), that is a set of scripts for using self-compiled builds of the OpenSSL library on the iPhone and the Apple TV.

However, this repository focuses more on framework-based setups and also adds macOS support.

# Compile library

Compile OpenSSL 1.0.2k for all archs:

```
./build-libssl.sh --version=1.0.2k
```

Compile OpenSSL 1.1.0f for all targets:

```
./build-libssl.sh --version=1.1.0f
```

Compile OpenSSL 1.0.2k for specific archs:

```
./build-libssl.sh --version=1.0.2k --archs="ios_armv7 ios_arm64 mac_i386"
```

Compile OpenSSL 1.1.0f for specific targets:

```
./build-libssl.sh --version=1.1.0f --targets="ios-cross-armv7 macos64-x86_64"
```

For all options see:

```
./build-libssl.sh --help
```

# Generate frameworks

Statically linked:

```
./create-openssl-framework.sh static
```

Dynamically linked:

```
./create-openssl-framework.sh dynamic
```

# Original project

* <https://github.com/x2on/OpenSSL-for-iPhone>

# Acknowledgements

This product includes software developed by the OpenSSL Project for use in the OpenSSL Toolkit. (<https://www.openssl.org/>)
