//
// RecoveryProgress.m
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

#import "RecoveryProgress.h"
#import "AppModel.h"
#include <cmath>
#include <memory>
#include <numeric>

Filter::Filter(size_t size)
: _samples(size, 0.0)
, _index{0}
, _is_poor{true}
{
}

void Filter::addSample(double value)
{
    _samples[_index] = value;
    _index = (_index + 1) % _samples.size();
    if (_is_poor)
    {
        _is_poor = _index + 1 < _samples.size();
    }
}

double Filter::getAverage() const
{
    double sum = accumulate(_samples.begin(), _samples.end(), 0.0);
    return sum / (_is_poor ? _index : _samples.size());
}

double Filter::getMedian() const
{
    std::vector<double> temp(_samples.begin(), _samples.end());
    size_t medianPos = (_is_poor ? _index : temp.size()) / 2;
    nth_element(temp.begin(),
                temp.begin() + medianPos,
                _is_poor ? temp.begin() + _index : temp.end());
    return temp[medianPos];
}


RecoveryProgress::RecoveryProgress()
{
 
}

RecoveryProgress::~RecoveryProgress()
{
    
}

double RecoveryProgress::getWindowedBps()
{
    if (!m_done)
        return 0.;
    
    auto timeDiff = m_lastUpdateTimestamp -
    (m_previousUpdateTimestamp
     ? m_previousUpdateTimestamp
     : m_startTimestamp);
    if (timeDiff < 1)
        timeDiff = 1;
    
    m_bpsWindowedFilter->addSample((m_done - m_lastDone) / static_cast<double>(timeDiff));
    return m_bpsWindowedFilter->getAverage();
}

double RecoveryProgress::getWholeTimeBps()
{
    if (!m_done)
        return 0.;
    
    auto timeDiff = beam::getTimestamp() - m_startTimestamp + 1;
    m_bpsWholeTimeFilter->addSample(m_done / static_cast<double>(timeDiff));
    return m_bpsWholeTimeFilter->getMedian();
}

int RecoveryProgress::getEstimate(double bps)
{
    m_estimateFilter->addSample((m_total - m_done) / bps);
    auto estimate = m_estimateFilter->getMedian();
    if (estimate > kMaxEstimate)
    {
        return kMaxEstimate;
    }
    else if (estimate < 2 * kSecondsInMinute)
    {
        return ceil(m_estimateFilter->getAverage());
    }
    else
    {
        return estimate;
    }
}

bool RecoveryProgress::OnProgress(uint64_t done, uint64_t total) {    
    if (!m_isStart) {
        m_isStart = true;
        
        m_bpsWholeTimeFilter = std::make_unique<Filter>(kFilterRange);
        m_bpsWindowedFilter = std::make_unique<Filter>(kFilterRange*3);
        m_estimateFilter = std::make_unique<Filter>(kFilterRange);
        
        m_startTimestamp = beam::getTimestamp();
    }
    
    m_previousUpdateTimestamp = m_lastUpdateTimestamp;
    m_lastUpdateTimestamp = beam::getTimestamp();
    m_lastDone = m_done;
    m_done = done;
    m_total = total;
    
    auto wbps = getWindowedBps();
    auto bps = (getWholeTimeBps() + wbps) / 2;
    
    if (bps) {
        m_estimate = getEstimate(bps);
    }

    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates){
        if ([delegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
            [delegate onRecoveryProgressUpdated:(int)done total:(int)total time:(int)m_estimate];
        }
    }
    
    return [AppModel sharedManager].isRestoreFlow;
}

