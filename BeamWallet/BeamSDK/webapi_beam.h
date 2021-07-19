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

#include "webapi_shaders.h"
#include "consent_handler.h"
#import "WalletModel.h"

namespace beamui::applications
{
    class WebAPI_Beam : public beam::wallet::IWalletApiHandler
    {
    public:
        explicit WebAPI_Beam(IConsentHandler& handler,
                             beam::wallet::IShadersManager::Ptr shaders,
                             const std::string& version,
                             const std::string& appid,
                             const std::string& appname,
                             beam::wallet::IWalletDB::Ptr walletDB,
                             beam::wallet::Wallet::Ptr wallet,
                             WalletModel::Ptr walletModel);

        ~WebAPI_Beam() override;

    //
    // Slots below are called by web in context of the UI thread
    //
       int test();
        void callWalletApi(const std::string& request);

    //
    // Signals are received by web
    //
        void callWalletApiResult(const std::string& result);

    public:
        void AnyThread_sendApproved(const std::string& request);
        void AnyThread_sendRejected(const std::string& request, beam::wallet::ApiError err, const std::string& message);
        void AnyThread_contractInfoApproved(const std::string& request);
        void AnyThread_contractInfoRejected(const std::string& request, beam::wallet::ApiError err, const std::string& message);

    public:
        // This can be called from any thread.
        void AnyThread_callWalletApiImp(const std::string& request);

        // This can be called from any thread
        void AnyThread_sendError(const std::string& request, beam::wallet::ApiError err, const std::string& message);

        // This can be called from any thread
        void AnyThread_sendAPIResponse(const beam::wallet::json& result);

        // This is called from API (REACTOR) thread
        void sendAPIResponse(const beam::wallet::json& result) override;

        // API should be accessed only in context of the reactor thread
        beam::wallet::IWalletApi::Ptr _walletAPI;
        IConsentHandler& _consentHandler;
        std::string _appId;
        std::string _appName;
        
        WalletModel::Ptr _walletModel;
        beam::wallet::Wallet::Ptr _wallet;
    };
}
