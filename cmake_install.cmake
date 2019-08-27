# Install script for directory: /Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet

# Set the install prefix
if(NOT DEFINED CMAKE_INSTALL_PREFIX)
  set(CMAKE_INSTALL_PREFIX "/usr/local")
endif()
string(REGEX REPLACE "/$" "" CMAKE_INSTALL_PREFIX "${CMAKE_INSTALL_PREFIX}")

# Set the install configuration name.
if(NOT DEFINED CMAKE_INSTALL_CONFIG_NAME)
  if(BUILD_TYPE)
    string(REGEX REPLACE "^[^A-Za-z0-9_]+" ""
           CMAKE_INSTALL_CONFIG_NAME "${BUILD_TYPE}")
  else()
    set(CMAKE_INSTALL_CONFIG_NAME "")
  endif()
  message(STATUS "Install configuration: \"${CMAKE_INSTALL_CONFIG_NAME}\"")
endif()

# Set the component getting installed.
if(NOT CMAKE_INSTALL_COMPONENT)
  if(COMPONENT)
    message(STATUS "Install component: \"${COMPONENT}\"")
    set(CMAKE_INSTALL_COMPONENT "${COMPONENT}")
  else()
    set(CMAKE_INSTALL_COMPONENT)
  endif()
endif()

# Is this installation the result of a crosscompile?
if(NOT DEFINED CMAKE_CROSSCOMPILING)
  set(CMAKE_CROSSCOMPILING "TRUE")
endif()

if(NOT CMAKE_INSTALL_LOCAL_ONLY)
  # Include the install script for each subdirectory.
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/3rdparty/libuv/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/3rdparty/secp256k1-zkp/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/3rdparty/libbitcoin/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/3rdparty/sqlite/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/utility/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/core/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/pow/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/p2p/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/http/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/wallet/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/node/cmake_install.cmake")
  include("/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/mnemonic/cmake_install.cmake")

endif()

if(CMAKE_INSTALL_COMPONENT)
  set(CMAKE_INSTALL_MANIFEST "install_manifest_${CMAKE_INSTALL_COMPONENT}.txt")
else()
  set(CMAKE_INSTALL_MANIFEST "install_manifest.txt")
endif()

string(REPLACE ";" "\n" CMAKE_INSTALL_MANIFEST_CONTENT
       "${CMAKE_INSTALL_MANIFEST_FILES}")
file(WRITE "/Users/Denis/Documents/Projects/Xcode/beam/beam-mainnet/${CMAKE_INSTALL_MANIFEST}"
     "${CMAKE_INSTALL_MANIFEST_CONTENT}")
