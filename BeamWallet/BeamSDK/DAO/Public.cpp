//
//  Public.m
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "Public.h"

const std::string kAppIDPrefix = "appid:";

std::string GenerateAppID(const std::string& appName, const std::string& appUrl)
{    
    ECC::Hash::Value hv;
    ECC::Hash::Processor() << appName << appUrl >> hv;
    
    auto appid = kAppIDPrefix + hv.str();
    return appid;
}

std::string StripAppIDPrefix(const std::string& appId)
{
    auto res = appId;
    
    size_t pos = appId.find(kAppIDPrefix);
    if (pos != std::string::npos)
    {
        res.erase(pos, kAppIDPrefix.length());
    }
    
    return res;
}
