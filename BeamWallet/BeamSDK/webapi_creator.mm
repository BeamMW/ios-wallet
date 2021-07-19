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

#include "webapi_creator.h"
#include "wallet/api/i_wallet_api.h"
#include "wallet/core/common.h"
#include "bvm/invoke_data.h"

namespace beamui::applications
{
    WebAPICreator::WebAPICreator(beam::wallet::IWalletDB::Ptr walletDB,
                             beam::wallet::Wallet::Ptr wallet, WalletModel::Ptr walletModel)
    {
        _walletDB = walletDB;
        _wallet = wallet;
        _walletModel = walletModel;
        _asyncWallet = walletModel->getAsync();
    }

    void WebAPICreator::createApi(const std::string &version, const std::string &appName, const std::string &appUrl)
    {
        using namespace beam::wallet;

        const auto stdver = version;
        if (!IWalletApi::ValidateAPIVersion(stdver))
        {
            NSLog(@"ERROR API VERSION");
        }

        ECC::Hash::Value hv;
        ECC::Hash::Processor() << appName << appUrl >> hv;
        const auto appid = std::string("appid:") + hv.str();

        _webShaders = std::make_shared<WebAPI_Shaders>(appid, appName);
        _api = std::make_unique<WebAPI_Beam>(*this, _webShaders, stdver, appid, appName, _walletDB, _wallet, _walletModel);
    }

    void WebAPICreator::AnyThread_getSendConsent(const std::string& request, const beam::wallet::IWalletApi::ParseResult& pinfo)
    {
        std::weak_ptr<bool> wp = _sendConsentGuard;
        _asyncWallet->makeIWTCall([] () -> boost::any {return boost::none;},
            [this, wp, request, pinfo](const boost::any&)
            {
                if (wp.lock())
                {
                    UIThread_getSendConsent(request, pinfo);
                }
                else
                {
                    LOG_WARNING() << "AT -> UIT send consent arrived but creator is already destroyed";
                }
            }
        );
    }

    void WebAPICreator::AnyThread_getContractInfoConsent(const std::string &request, const beam::wallet::IWalletApi::ParseResult& pinfo)
    {
        std::weak_ptr<bool> wp = _sendConsentGuard;
        _asyncWallet->makeIWTCall([] () -> boost::any {return boost::none;},
            [this, wp, request, pinfo](const boost::any&)
            {
                if (wp.lock())
                {
                    UIThread_getContractInfoConsent(request, pinfo);
                }
                else
                {
                    LOG_WARNING() << "AT -> UIT contract consent arrived but creator is already destroyed";
                }
            }
        );
    }

    void WebAPICreator::UIThread_getSendConsent(const std::string& request, const beam::wallet::IWalletApi::ParseResult& pinfo)
    {
        this->sendApproved(request);
    }

    void WebAPICreator::UIThread_getContractInfoConsent(const std::string& request, const beam::wallet::IWalletApi::ParseResult& pinfo)
    {
        this->contractInfoApproved(request);
    }

    void WebAPICreator::sendApproved(const std::string& request)
    {
        _api->AnyThread_sendApproved(request);
    }

    void WebAPICreator::sendRejected(const std::string& request)
    {
        _api->AnyThread_sendRejected(request, beam::wallet::ApiError::UserRejected, std::string());
    }

    void WebAPICreator::contractInfoApproved(const std::string& request)
    {
        _api->AnyThread_contractInfoApproved(request);
    }

    void WebAPICreator::contractInfoRejected(const std::string& request)
    {
        _api->AnyThread_contractInfoRejected(request, beam::wallet::ApiError::UserRejected, std::string());
    }
}
