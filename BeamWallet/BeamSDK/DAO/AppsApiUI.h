//
//  AppsApiUI.h
//  BeamWallet
//
//  Created by Denis on 31.08.2021.
//  Copyright © 2021 Denis. All rights reserved.
//

#include "wallet/api/i_wallet_api.h"
#include "wallet/core/contracts/i_shaders_manager.h"
#include "wallet/client/apps_api/apps_api.h"


class AppsApiUI : public beam::wallet::AppsApi<AppsApiUI>
{

public:
    AppsApiUI(const std::string& appid, const std::string& appname);
    ~AppsApiUI() override = default;
  
    int test();
    void callWalletApi(const std::string& request);
    void sendApproved(const std::string& request);
    void sendRejected(const std::string& request);
    void contractInfoApproved(const std::string& request);
    void contractInfoRejected(const std::string& request);

private:
    
    friend class beam::wallet::AppsApi<AppsApiUI>;
    
    void AnyThread_sendApiResponse(const std::string& result) override;
    void ClientThread_getSendConsent(const std::string& request, const nlohmann::json& info, const nlohmann::json& amounts) override;
    void ClientThread_getContractConsent(const std::string& request, const nlohmann::json& info, const nlohmann::json& amounts) override;
    
private:    
    std::string prepareInfo4QT(const nlohmann::json& info);
    std::string prepareAmounts4QT(const nlohmann::json& amounts);
    std::string AmountToUIString(const beam::Amount& value);
};


