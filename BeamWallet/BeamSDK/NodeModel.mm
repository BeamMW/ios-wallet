//
// NodeModel.m
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

#import "NodeModel.h"
#import "Settings.h"
#import "StringStd.h"
#import "AppModel.h"

#include "node/node.h"
#include <mutex>

#include "pow/external_pow.h"

#include <boost/filesystem.hpp>


using namespace beam;
using namespace beam::io;
using namespace std;

NSString *const AppErrorDomain = @"beam.mw";

NodeModel::NodeModel()
: m_nodeClient(this)
{
    isAlreadyStarted = false;
}

void NodeModel::setKdf(beam::Key::IKdf::Ptr kdf)
{
    m_nodeClient.setKdf(kdf);
}

void NodeModel::startNode()
{
    
    try{
        m_nodeClient.startNode();
    }
    catch (const std::exception& e) {
        
    }
    catch (...) {
        
    }
}

void NodeModel::stopNode()
{
    
    try{
        m_nodeClient.stopNode();
    }
    catch (const std::exception& e) {
        
    }
    catch (...) {
        
    }
}

void NodeModel::start()
{
    try{
        m_nodeClient.start();
    }
    catch (const std::exception& e) {
        
    }
    catch (...) {
        
    }
}

bool NodeModel::isNodeRunning() const
{
    return m_nodeClient.isNodeRunning();
}

bool NodeModel::isStarted() const
{
    return isAlreadyStarted;
}

void NodeModel::onSyncProgressUpdated(int done, int total)
{
    NSLog(@"onSyncProgressUpdated %d/%d",done,total);
    
    [AppModel sharedManager].isUpdating = (done != total);
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onSyncProgressUpdated: total:)]) {
            [delegate onSyncProgressUpdated:done total:total];
        }
    }
}

void NodeModel::onStartedNode()
{
    NSLog(@"onStartedNode");
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [AppModel sharedManager].isLocalNodeStarted = YES;
    });
}

void NodeModel::onStoppedNode()
{
    NSLog(@"onStoppedNode");
    
    [AppModel sharedManager].isLocalNodeStarted = NO;
}

void NodeModel::onFailedToStartNode(io::ErrorCode errorCode)
{
    NSLog(@"onFailedToStartNode");
    
    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletError:)]) {
            NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                                       code:NSUInteger(12)
                                                   userInfo:@{ NSLocalizedDescriptionKey:@"Failed to start wallet" }];
            
            [delegate onWalletError:nativeError];
        }
    }
}

//void NodeModel::onFailedToStartNode()
//{
//    NSLog(@"onFailedToStartNode");
//
//    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
//    {
//        if ([delegate respondsToSelector:@selector(onWalletError:)]) {
//            NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
//                                                       code:NSUInteger(12)
//                                                   userInfo:@{ NSLocalizedDescriptionKey:@"Failed to start wallet" }];
//
//            [delegate onWalletError:nativeError];
//        }
//    }
//}

void NodeModel::onSyncError(beam::Node::IObserver::Error error)
{
    NSLog(@"onFailedToStartNode");

    for(id<WalletModelDelegate> delegate in [AppModel sharedManager].delegates)
    {
        if ([delegate respondsToSelector:@selector(onWalletError:)]) {
            NSError *nativeError = [NSError errorWithDomain:AppErrorDomain
                                                       code:NSUInteger(12)
                                                   userInfo:@{ NSLocalizedDescriptionKey:@"Failed to start wallet" }];

            [delegate onWalletError:nativeError];
        }
    }
}

void NodeModel::onNodeThreadFinished()
{
    
}


uint16_t NodeModel::getLocalNodePort()
{
    return [[Settings sharedManager] nodePort];
}

std::string NodeModel::getLocalNodeStorage()
{
    return [[Settings sharedManager] localNodeStorage].string;
}

std::string NodeModel::getTempDir()
{
    return [[Settings sharedManager] localNodeTemdDir].string;
}

std::vector<std::string> NodeModel::getLocalNodePeers()
{
    std::vector<std::string> result;
    
    for (NSString *node in [[Settings sharedManager] localNodePeers])
    {
        result.push_back(node.string);
    }
    
    return result;
}
