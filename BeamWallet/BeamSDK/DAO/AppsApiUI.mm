//
//  AppsApiUI.m
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#import "AppsApiUI.h"
#import "AppModel.h"

#include <boost/regex.hpp>
#include <boost/optional.hpp>

#include "utility/logger.h"
#include "utility/bridge.h"
#include "utility/io/asyncevent.h"
#include "utility/helpers.h"
#include "utility/common.h"

#include <sstream>

#import "StringStd.h"
#import "Public.h"


AppsApiUI::AppsApiUI(const std::string& appid, const std::string& appname) : AppsApi<AppsApiUI>(appid, appname)
{

}

int AppsApiUI::test()
{
    // only for test, always 42
    return 42;
}

void AppsApiUI::sendApproved(const std::string& request)
{
    LOG_INFO() << "Contract send approved: " << getAppName() << ", " << getAppId() << ", " << request;
    AnyThread_callWalletApiDirectly(request);
}

void AppsApiUI::sendRejected(const std::string& request)
{
    LOG_INFO() << "Contract send rejected: " << getAppName() << ", " << getAppId() << ", " << request;
    AnyThread_sendApiError(request, beam::wallet::ApiError::UserRejected, std::string());
}

void AppsApiUI::contractInfoApproved(const std::string& request)
{
    LOG_INFO() << "Contract tx approved: " << getAppName() << ", " << getAppId() << ", " << request;
    AnyThread_callWalletApiDirectly(request);
}

void AppsApiUI::contractInfoRejected(const std::string& request)
{
    LOG_INFO() << "Contract tx rejected: " << getAppName() << ", " << getAppId() << ", " << request;
    AnyThread_sendApiError(request, beam::wallet::ApiError::UserRejected, std::string());
}

void AppsApiUI::callWalletApi(const std::string& request)
{
    LOG_INFO() << "Call Wallet Api: " << getAppName() << ", " << getAppId() << ", " << request;
    AnyThread_callWalletApiChecked(request);
}

void AppsApiUI::AnyThread_sendApiResponse(const std::string& result)
{
    LOG_INFO() << "Send Api Response: " << getAppName() << ", " << getAppId() << ", " << result;
    NSString *json = [NSString stringWithUTF8String:result.c_str()];
    [[AppModel sharedManager] sendDAOApiResult:json];
}

void AppsApiUI::ClientThread_getSendConsent(const std::string& request, const nlohmann::json& jinfo, const nlohmann::json& jamounts)
{
    if (!jamounts.is_array() || jamounts.size() != 1)
    {
        assert(false);
        return AnyThread_sendApiError(request, beam::wallet::ApiError::NotAllowedError, "send must spend strictly 1 asset");
    }
    
    const auto info = prepareInfo4QT(jinfo);
    const auto amounts = prepareAmounts4QT(jamounts);
    
   // emit approveSend(QString::fromStdString(request), info, amounts);
}

void AppsApiUI::ClientThread_getContractConsent(const std::string& request, const nlohmann::json& jinfo, const nlohmann::json& jamounts)
{
    const auto info = prepareInfo4QT(jinfo);
    const auto amounts = prepareAmounts4QT(jamounts);
   
    NSString *json = [NSString stringWithUTF8String:request.c_str()];
    NSString *inf = [NSString stringWithUTF8String:info.c_str()];
    NSString *am = [NSString stringWithUTF8String:amounts.c_str()];

    [[AppModel sharedManager] approveContractInfo:json info:inf amounts:am];
}

std::string AppsApiUI::prepareInfo4QT(const nlohmann::json& info)
{
    nlohmann::json result = nlohmann::json::object();
    for (const auto& kv: info.items())
    {
        if (kv.key() == "fee")
        {
            const auto fee = AmountToUIString(info["fee"].get<beam::Amount>());
            result["fee"] = fee;
            
            const auto feeRate = ""; //AmountToUIString(_amgr->getRate(beam::Asset::s_BeamID));
            result["feeRate"]  = feeRate;
            result["rateUnit"] =  "";//_amgr->getRateUnit().toStdString();
        }
        else
        {
            result.push_back({kv.key(), kv.value()});
        }
    }
    
    return result.dump();
}

std::string AppsApiUI::prepareAmounts4QT(const nlohmann::json& amounts)
{
    nlohmann::json result = nlohmann::json::array();
    for (const auto& val: amounts)
    {
        const auto assetId = val["assetID"].get<beam::Asset::ID>();
        const auto amount = val["amount"].get<beam::Amount>();
        const auto spend = val["spend"].get<bool>();
        
        result.push_back({
            {"assetID", assetId},
            {"amount", AmountToUIString(amount)},
            {"spend", spend}
        });
    }
    
    return result.dump();
}

std::string AppsApiUI::AmountToUIString(const beam::Amount& value)
{
    double realAmount = (double(int64_t(beam::AmountBig::get_Lo(value))) / beam::Rules::Coin);
    return [[NSString stringWithFormat:@"%f", realAmount] string];
}
