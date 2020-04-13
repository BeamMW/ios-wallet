//
// Fonts.swift
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


import Foundation

func BoldFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProDisplay-Bold", size: size) ?? UIFont.systemFont(ofSize: size)
}

func RegularFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProDisplay-Regular", size: size) ?? UIFont.boldSystemFont(ofSize: size)
}

func ItalicFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProDisplay-Italic", size: size) ?? UIFont.italicSystemFont(ofSize: size)
}

func SemiboldFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProDisplay-Semibold", size: size) ?? UIFont.boldSystemFont(ofSize: size)
}

func LightFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProDisplay-Light", size: size) ?? UIFont.boldSystemFont(ofSize: size)
}

func ProMediumFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProText-Medium", size: size) ?? UIFont.boldSystemFont(ofSize: size)
}

func ProRegularFont(size:CGFloat) -> UIFont {
    return UIFont(name: "SFProText-Regular", size: size) ?? UIFont.boldSystemFont(ofSize: size)
}
