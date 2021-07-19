// Copyright 2018 The Beam Team
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
#pragma once

#include "consent_handler.h"
#include "webapi_beam.h"
#include "webapi_shaders.h"

namespace beamui::applications
{
    class WebAPICreator
        : public IConsentHandler
    {
    public:
        explicit WebAPICreator(beam::wallet::IWalletDB::Ptr walletDB,
                               beam::wallet::Wallet::Ptr wallet,
                               WalletModel::Ptr walletModel);

        void createApi(const std::string& version, const std::string& appName, const std::string& appUrl);
        void sendApproved(const std::string& request);
        void sendRejected(const std::string& request);
        void contractInfoApproved(const std::string& request);
        void contractInfoRejected(const std::string& request);


    public:
        void AnyThread_getSendConsent(const std::string& request, const beam::wallet::IWalletApi::ParseResult&) override;
        void AnyThread_getContractInfoConsent(const std::string &request, const beam::wallet::IWalletApi::ParseResult &) override;

        void UIThread_getSendConsent(const std::string& request, const beam::wallet::IWalletApi::ParseResult&);
        void UIThread_getContractInfoConsent(const std::string& request, const beam::wallet::IWalletApi::ParseResult&);

        std::unique_ptr<WebAPI_Beam> _api;
        WebAPI_Shaders::Ptr _webShaders;
        beam::wallet::IWalletModelAsync::Ptr _asyncWallet;

        beam::wallet::IWalletDB::Ptr _walletDB;
        WalletModel::Ptr _walletModel;
        beam::wallet::Wallet::Ptr _wallet;
        
        std::shared_ptr<bool> _sendConsentGuard = std::make_shared<bool>(true);
        std::shared_ptr<bool> _contractConsentGuard = std::make_shared<bool>(true);
    };
}
