//
// Resources.swift
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

func IconShowBalance() -> UIImage? {
    return UIImage(named: "iconShowBalance")
}

func IconHideBalance() -> UIImage? {
    return UIImage(named: "iconHideBalance")
}

func MoreIcon() -> UIImage? {
    return UIImage(named: "iconMore")
}

func IconCopyBlue() -> UIImage? {
    return UIImage(named: "iconCopyBlue")
}

func IconSymbolBeam() -> UIImage? {
    return UIImage(named: "iconSymbol")
}

func IconSendPink() -> UIImage? {
    return UIImage(named: "iconSendPink")
}

func IconCopyWhite() -> UIImage? {
    return UIImage(named: "iconCopyWhite")
}

func IconUtxo() -> UIImage? {
    return UIImage(named: "iconUtxo")
}

func IconReceiveLightBlue() -> UIImage? {
    return UIImage(named: "iconReceiveLightBlue")
}

func BackgroundTestnet() -> UIImage? {
    return UIImage(named: "bgTestnet.jpg")
}

func BackgroundMasternet() -> UIImage? {
    return UIImage(named: "bgMasternet.jpg")
}

func BackgroundDark() -> UIImage? {
    return UIImage(named: "bgBlack.jpg")
}


func IconBack() -> UIImage? {
    return UIImage(named: "iconBack")
}

func IconWallet() -> UIImage? {
    return UIImage(named: "iconWallet")
}

func IconAddresses() -> UIImage? {
    return UIImage(named: "iconAddresses")
}


func IconNotifications() -> UIImage? {
    return UIImage(named: "iconNotificationMenu")
}

func IconSettings() -> UIImage? {
    return UIImage(named: "iconSettings")
}

func CheckboxFull() -> UIImage? {
    return UIImage(named: "checkboxFull")
}

func CheckboxEmptyNew() -> UIImage? {
    return UIImage(named: "icnCheckmarkEmpty")
}

func CheckboxEmpty() -> UIImage? {
    return UIImage(named: "checkboxEmpty")
}

func RateLogo() -> UIImage? {
    return UIImage(named: "rateLogo")
}

func IconNextLightBlue() -> UIImage? {
    return UIImage(named: "iconNextLightBlue")
}

func IconBuyLogo() -> UIImage? {
    return UIImage(named: "iconBuyLogo")
}

func IconExternalLinkGray() -> UIImage? {
    return UIImage(named: "iconExternalLinkGray")
}

func MenuSelectedBackground() -> UIImage? {
    return UIImage(named: "MenuSelectedBackground")
}

func IconLogout() -> UIImage? {
    return UIImage(named: "iconLogout")
}

func IconLeftMenu() -> UIImage? {
    return UIImage(named: "iconLeftMenu")
}

func IconDownArrow() -> UIImage? {
    if Settings.sharedManager().isDarkMode {
        return UIImage(named: "iconDownArrow")?.maskWithColor(color: UIColor.main.steel)
    }
    else{
        return UIImage(named: "iconDownArrow")
    }
}

func IconNextArrow() -> UIImage? {
    if Settings.sharedManager().isDarkMode {
        return UIImage(named: "iconNextArrow")?.maskWithColor(color: UIColor.main.steel)
    }
    else{
        return UIImage(named: "iconNextArrow")
    }
}

func GradientBlue() -> UIImage? {
    return UIImage(named: "gradientBlue")
}

func IconScanQr() -> UIImage? {
    return UIImage(named: "iconScanQr")
}

func IconNextPink() -> UIImage? {
    return UIImage(named: "iconNextPink")
}

func SliderDot() -> UIImage? {
    return UIImage(named: "sliderDot")
}

func SliderDotGreen() -> UIImage? {
    return UIImage(named: "sliderDotGreen")
}

func IconSendBlue() -> UIImage? {
    return UIImage(named: "iconSendBlue")
}

func IconUnlinkSmall() -> UIImage? {
    return UIImage(named: "iconUnlinkSmall")
}

func IconDoneBlue() -> UIImage? {
    return UIImage(named: "iconDoneBlue")
}

func IconCancel() -> UIImage? {
    return UIImage(named: "iconCancel")
}

func IconCancelWhite() -> UIImage? {
    return UIImage(named: "iconCancel")?.maskWithColor(color: UIColor.white)
}

func IconComment() -> UIImage? {
    return UIImage(named: "iconComment")
}

func IconRowCancel() -> UIImage? {
    return UIImage(named: "iconRowCancel")
}

func IconRowEdit() -> UIImage? {
    return UIImage(named: "iconRowEdit")
}

func IconRowCopy() -> UIImage? {
    return UIImage(named: "iconRowCopy")
}

func IconRowDelete() -> UIImage? {
    return UIImage(named: "iconRowDelete")
}

func IconRowRepeat() -> UIImage? {
    return UIImage(named: "iconRowRepeat")
}

func IconTouchid() -> UIImage? {
    return UIImage(named: "iconTouchidSmall")
}

func IconShufflePink() -> UIImage? {
    return UIImage(named: "iconShufflePink")
}

func IconSearchSmall() -> UIImage? {
    return UIImage(named: "iconSearchSmall")
}

func IconFaceId() -> UIImage? {
    return UIImage(named: "iconFaceId")
}

func Tick() -> UIImage? {
    return UIImage(named: "tick")
}

func IconInfinity() -> UIImage? {
    if Settings.sharedManager().isDarkMode {
        return UIImage(named: "iconInfinity")?.maskWithColor(color: UIColor.main.steel)
    }
    else{
        return UIImage(named: "iconInfinity")
    }
}

func IconExpires() -> UIImage? {
    if Settings.sharedManager().isDarkMode {
        return UIImage(named: "iconExpires")?.maskWithColor(color: UIColor.main.steel)
    }
    else{
        return UIImage(named: "iconExpires")
    }
}

func ClearIcon() -> UIImage? {
    return UIImage(named: "clearIcon")
}

func IconExpired() -> UIImage? {
    if Settings.sharedManager().isDarkMode {
        return UIImage(named: "iconExpired")?.maskWithColor(color: UIColor.main.steel)
    }
    else{
        return UIImage(named: "iconExpired")
    }
}

func IconBeam() -> UIImage? {
    return UIImage(named: "iconBeam")
}

func IconNotifictionsUpdate() -> UIImage? {
    return UIImage(named: "iconNotifictionsUpdate")
}

func IconUtxoEmpty() -> UIImage? {
    return UIImage(named: "iconUtxoEmptyState")
}

func IconUnlinkedTransaction() -> UIImage? {
    return UIImage(named: "iconUnlinkedTransaction")
}

func IconStopUnlinking() -> UIImage? {
    return UIImage(named: "iconStopUnlinking")
}

func IconNotifictionsExpired() -> UIImage? {
    return UIImage(named: "iconNotifictionsExpired")
}

func IconNotificationsEmpty() -> UIImage? {
    return UIImage(named: "iconNotificationEmpty")
}

func IconAddressbookEmpty() -> UIImage? {
    return UIImage(named: "iconAddressbookEmptyState")
}

func IconWalletEmpty() -> UIImage? {
    return UIImage(named: "iconWalletEmpty")
}

func IconCloud() -> UIImage? {
    return UIImage(named: "icnCloud")
}

func IconManual() -> UIImage? {
    return UIImage(named: "icnLaptop")
}

func IconNextBlue() -> UIImage? {
    return UIImage(named: "iconNextBlue")
}

func IconCheckmarkEmpty() -> UIImage? {
    return UIImage(named: "icnCheckmarkEmpty")
}

func IconCheckmarkFull() -> UIImage? {
    return UIImage(named: "icnCheckmarkFull")
}

func IconAdd() -> UIImage? {
    return UIImage(named: "icnAdd")
}

func IconQR() -> UIImage? {
    return UIImage(named: "iconQr")
}

func IconEdit() -> UIImage? {
    return UIImage(named: "icnEdit")
}

func IconUTXOSecurity() -> UIImage? {
    return UIImage(named: "icEyeCrossedBig")
}

func IconSent() -> UIImage? {
    return UIImage(named: "icon-sent")
}

func IconReceived() -> UIImage? {
    return UIImage(named: "icon-received")
}

func ExternalLinkGreen() -> UIImage? {
    return UIImage(named: "iconExternalLinkGreen")
}

func IconContact() -> UIImage? {
    return UIImage(named: "iconContact")
}

func IconSaveDone() -> UIImage? {
    return UIImage(named: "iconDoneBlue")
}

func IconSeedPhrase() -> UIImage? {
    if Settings.sharedManager().isDarkMode {
        return UIImage(named: "iconSeedPhrase")?.maskWithColor(color: UIColor.main.marine)
    }
    else{
        return UIImage(named: "iconSeedPhrase")?.maskWithColor(color: UIColor.main.marineOriginal)
    }
}

func IconNode() -> UIImage? {
    return UIImage(named: "iconNode")
}

func IconSettingsGeneral() -> UIImage? {
    return UIImage(named: "iconSettingsGeneral")
}

func IconSettingsPrivacy() -> UIImage? {
    return UIImage(named: "iconSettingsPrivacy")
}

func IconSettingsRate() -> UIImage? {
    return UIImage(named: "iconSettingsRate")
}

func IconSettingsRemove() -> UIImage? {
    return UIImage(named: "iconSettingsRemove")
}

func IconSettingsReport() -> UIImage? {
    return UIImage(named: "iconSettingsReport")
}

func IconSettingsTags() -> UIImage? {
    return UIImage(named: "iconSettingsTags")
}

func IconSettingsUtilities() -> UIImage? {
    return UIImage(named: "iconSettingsUtilities")
}

