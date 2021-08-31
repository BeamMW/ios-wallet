//
//  WebAPICreator.h
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "WalletModel.h"
#import "AppsApiUI.h"

#include "wallet/api/i_wallet_api.h"
#include "wallet/core/contracts/i_shaders_manager.h"
#include "wallet/client/apps_api/apps_api.h"

class WebAPICreator {
    
public:
    explicit WebAPICreator(WalletModel::Ptr walletModel);
    
    void createApi(const std::string& verWant, const std::string& verMin, const std::string& appName, const std::string& appUrl);
    bool apiSupported(const std::string& apiVersion) const;
    std::string generateAppID(const std::string& appName, const std::string& appUrl);
    
    void apiChanged();
    
    WalletModel::Ptr _walletModel;
    std::shared_ptr<AppsApiUI> _api;
};

