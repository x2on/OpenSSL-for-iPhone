#!/bin/sh

set -u
LIBNAME=openssl
XFWNAME=OpenSSL.xcframework

if [ ! -d lib ]; then
    echo "Please run build-libssl.sh first!"
    exit 1
fi

if [ -d $XFWNAME ]; then
    echo "* Removing existing $XFWNAME copy"
    rm -rf $XFWNAME
fi

LIBS=""
LIBTOOL_FLAGS="-no_warning_for_no_symbols -static"

# Combine libssl and libcrypto into single per-platform library
make_platform_lib()
{
  SLICE_LIBS=`ls lib/lib*-$SLICE.a 2>/dev/null`
  SLICE_OUT="lib/OpenSSL-$SLICE.a"
  if [ ${#SLICE_LIBS} -gt 0 ]; then
    echo "* Creating library for $SLICE"
    libtool $LIBTOOL_FLAGS -o $SLICE_OUT $SLICE_LIBS
    if [ $? -ne 0 ]; then
      exit 1
    fi
    LIBS="$LIBS -library $SLICE_OUT -headers include/$LIBNAME"
  else
    echo "* Skipping $SLICE. No libraries found."
  fi
}

remove_platform_libs()
{
  rm lib/OpenSSL-*.a
}

remove_platform_libs
PLATFORMS="iOS tvOS watchOS Catalyst"
for PLATFORM in $PLATFORMS
do
  SLICE="$PLATFORM"
  make_platform_lib
  SLICE="$PLATFORM-Sim"
  make_platform_lib
done

echo "* Creating $XFWNAME"
xcodebuild -create-xcframework $LIBS -output $XFWNAME
remove_platform_libs
echo "Done!"
