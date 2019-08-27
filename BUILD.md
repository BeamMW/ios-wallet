# How to build BEAM libraries

#####Before building the BEAM libraries you should build boost and openssl libraries

###### Boost

- download https://github.com/faithfracture/Apple-Boost-BuildScript
- change boost.sh: add arm64e architecture to IOS_ARCHS=("armv7 arm64")
- build

###### OpenSSL

- download https://github.com/levigroker/GRKOpenSSLFramework
- change build.sh: add build "arm64e" "${IPHONEOS_SDK}" "ios" below build "arm64" "${IPHONEOS_SDK}" "ios"
-  build

###### After building boost and openssl

- Download mainnet, masternet, testnet sources of BEAM
- Copy build_ios.sh, cmake_install.cmake  from iOS project to beam sources project
- Change export properties in build_ios.sh. Paste your paths for boost and openssl libraries
- Open terminal and run build_ios.sh

# How to build iOS project

- Install cocoa pods
- Add a boost library to the project
- Add a latest BEAM libraries: mainnet, masternet, testnet
- Change the header search paths, depending on where your libraries are
