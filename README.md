[alt text](https://forum.beam-mw.com/uploads/beam_mw/original/1X/261e2a2eba2b6c8aadae678673f9e8e09a78f5cf.png "Beam Logo")

[twitter](https://twitter.com/beamprivacy) | [medium](https://medium.com/beam-mw) | [reddit](https://www.reddit.com/r/beamprivacy/) | [beam forum](http://forum.beam-mw.com) | [gitter](https://gitter.im/beamprivacy/Lobby) | [telegram](https://t.me/BeamPrivacy) | [bitcointalk](https://bitcointalk.org/index.php?topic=5052151.0) | [youtube](https://www.youtube.com/channel/UCddqBnfSPWibf4f8OnEJm_w?)

Beam wallet app for iOS allows to confidentially exchange funds anywhere you are.

Read documentation [here](https://documentation.beam.mw).

Things that make BEAM special include:

* Users have complete control over privacy - a user decides which information will be available and to which parties, having complete control over his personal data in accordance to his will and applicable laws.
* Confidentiality without penalty - in BEAM confidential transactions do not cause bloating of the blockchain, avoiding excessive computational overhead or penalty on performance or scalability while completely concealing the transaction value.
* No trusted setup required
* Blocks are mined using Equihash Proof-of-Work algorithm.
* Limited emission using periodic halving.
* No addresses are stored in the blockchain - no information whatsoever about either the sender or the receiver of a transaction is stored in the blockchain.
* Superior scalability through compact blockchain size - using the “cut-through” feature of Mimblewimble makes the BEAM blockchain orders of magnitude smaller than any other blockchain implementation.
* BEAM supports many transaction types such as escrow transactions, time locked transactions, atomic swaps and more.


# Roadmap
- March 2019    : Tesnet Betas
- April 2019    : Mainnet release

# Current status
- First Testnet development started

# Known limitations and workarounds:
- Restore flow is not implemented on mobile, yet the funds can be restored from the desktop wallet using the same seed the mobile wallet was created with

# How to build

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

# Support

