//
//  WebAPICreator.m
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "WebAPICreator.h"
#import "AppsApiUI.h"

#include "wallet/api/i_wallet_api.h"
#include "wallet/core/common.h"
#include "bvm/invoke_data.h"
#include "Public.h"


WebAPICreator::WebAPICreator()
{
}


void WebAPICreator::destroyApi()
{
    _api.reset();
}


void WebAPICreator::createApi(const std::string& verWant, const std::string& verMin, const std::string &appName, const std::string &appUrl)
{
    
    std::string version;
    if (beam::wallet::IWalletApi::ValidateAPIVersion(verWant))
    {
        version = verWant;
    }
    
    else if (beam::wallet::IWalletApi::ValidateAPIVersion(verMin))
    {
        version = verMin;
    }
    
    const auto appid = GenerateAppID(appName, appUrl);
    
    auto guard = this;
    
    AppsApiUI::ClientThread_Create(_walletModel.get(), version, appid, appName, false,
                                   [this, guard, version, appName, appid] (AppsApiUI::Ptr api) {
        if (guard)
        {
            _api = std::move(api);
            LOG_INFO() << "API created: " << version << ", " << appName << ", " << appid;
        }
        else
        {
            LOG_INFO() << "WebAPICreator destroyed before api created:" << version << ", " << appName << ", " << appid;
        }
    });
}

bool WebAPICreator::apiSupported(const std::string& apiVersion) const
{
    return beam::wallet::IWalletApi::ValidateAPIVersion(apiVersion);
}

std::string WebAPICreator::generateAppID(const std::string& appName, const std::string& appUrl)
{
    const auto appid = GenerateAppID(appName, appUrl);
    return appid;
}
