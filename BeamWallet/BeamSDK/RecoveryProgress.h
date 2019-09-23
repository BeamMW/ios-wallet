//
// RecoveryProgress.h
// BeamWallet
//
// Copyright 2018 Beam Development
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#import <Foundation/Foundation.h>
#include "wallet/wallet_client.h"
#include "wallet/common.h"

class Filter
{
public:
    Filter(size_t size = 12);
    void addSample(double value);
    double getAverage() const;
    double getMedian() const;
private:
    std::vector<double> _samples;
    size_t _index;
    bool _is_poor;
};


struct RecoveryProgress : public beam::wallet::IWalletDB::IRecoveryProgress 
{
    RecoveryProgress();
    ~RecoveryProgress();
    
private: bool m_isStart = false;

private: int kFilterRange = 10;
private: double kSecondsInMinute = 60.0;
private: double kSecondsInHour = 60.0 * 60.0;
private: double kMaxEstimate = 4 * kSecondsInHour;
    
private: uint64_t m_total = 0;
private: uint64_t m_done = 0;
private: uint64_t m_lastDone = 0;
private: uint64_t m_estimate = 0;

private: long m_startTimestamp = 0;
private: long m_previousUpdateTimestamp = 0;
private: long m_lastUpdateTimestamp = 0;

private: std::unique_ptr<Filter> m_bpsWholeTimeFilter;
private: std::unique_ptr<Filter> m_bpsWindowedFilter;
private: std::unique_ptr<Filter> m_estimateFilter;

    
private:
    double getWindowedBps();
    double getWholeTimeBps();
    int getEstimate(double bps);
    
public:
    bool OnProgress(uint64_t done, uint64_t total) override;
};
