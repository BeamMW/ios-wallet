#!/bin/sh

#  build_ios.sh
#  wallet_test
#
#  Created by Denis on 2/27/19.
#  Copyright © 2019 Denis. All rights reserved.
#
######## Boost Framework
#
#   1) download https://github.com/faithfracture/Apple-Boost-BuildScript
#   2) change boost.sh - add arm64e architecture to IOS_ARCHS=("armv7 arm64")
#   3) build
#   4) copy boost fraemwork to /Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS12.0.sdk/System/Library/Frameworks
#
######## Open SSL
#
#   1) download https://github.com/levigroker/GRKOpenSSLFramework
#   2) change build.sh - add build "arm64e" "${IPHONEOS_SDK}" "ios" below build "arm64" "${IPHONEOS_SDK}" "ios"
#   3) build


export OPENSSL_ROOT_DIR="/YOUR PATH/openssl"
export OPENSSL_CRYPTO_LIBRARY="/YOUR PATH/openssl/lib/libcrypto.a"
export OPENSSL_INCLUDE_DIR="/YOUR PATH//openssl/include"
export OPENSSL_SSL_LIBRARY="/YOUR PATH/openssl/lib/libssl.a"
export OPENSSL_LIBRARIES="/YOUR PATH/openssl/lib/"
export BOOST_ROOT_IOS="/YOUR PATH/boost"

cmake . -DCMAKE_TOOLCHAIN_FILE=ios.toolchain.cmake -DBEAM_NO_QT_UI_WALLET=ON -DIOS_PLATFORM=OS64 -DCMAKE_CXX_FLAGS=-stdlib=libc++ -DIOS_DEPLOYMENT_TARGET=11.0 -DENABLE_BITCODE=0 -DOPENSSL_ROOT_DIR=$OPENSSL_ROOT_DIR -DOPENSSL_CRYPTO_LIBRARY=$OPENSSL_CRYPTO_LIBRARY -DOPENSSL_INCLUDE_DIR=$OPENSSL_INCLUDE_DIR -DOPENSSL_SSL_LIBRARY=$OPENSSL_SSL_LIBRARY -DOPENSSL_LIBRARIES=$OPENSSL_LIBRARIES -DIOS=YES -DBOOST_ROOT_IOS=$BOOST_ROOT_IOS -Wno-error=deprecated-declarations -Wno-error=deprecated -DCMAKE_TRY_COMPILE_PLATFORM_VARIABLES=CMAKE_WARN_DEPRECATED
