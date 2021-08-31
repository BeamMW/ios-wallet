//
//  Public.h
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#include "wallet/api/i_wallet_api.h"
#include "wallet/core/contracts/i_shaders_manager.h"
#include "wallet/client/apps_api/apps_api.h"

std::string GenerateAppID(const std::string& appName, const std::string& appUrl);
std::string StripAppIDPrefix(const std::string& appId);
