//
//  WebAPICreator.m
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2026 Denis. All rights reserved.
//

#import "WebAPICreator.h"
#import "AppsApiUI.h"

#include "wallet/api/i_wallet_api.h"
#include "wallet/core/common.h"
#include "bvm/invoke_data.h"
#include "utility/logger.h"
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
    
    // `ipfsnode=true` makes ClientThread_Create call IWThread_startIPFSNode on
    // the wallet thread and stash the IPFS service handle on the resulting
    // ApiInitData. Without it, `ipfs_get` on this API instance returns
    // ApiError::NotSupported even when BEAM_IPFS_SUPPORT is on. Callers must
    // have set the IPFS config (repo_root, swarm key) on the wallet client
    // before invoking createApi — AppModel does this at wallet-open time.
    AppsApiUI::ClientThread_Create(_walletModel.get(), version, appid, appName, 0, true,
                                   [this, guard, version, appName, appid] (AppsApiUI::Ptr api) {
        if (guard)
        {
            _api = std::move(api);
            BEAM_LOG_INFO() << "API created: " << version << ", " << appName << ", " << appid;
        }
        else
        {
            BEAM_LOG_INFO() << "WebAPICreator destroyed before api created:" << version << ", " << appName << ", " << appid;
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
