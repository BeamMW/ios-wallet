//
// RestoreManager.swift
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

import Foundation

class RestoreManager: NSObject {
    
    static var shared = RestoreManager()

    private var completion : ((Bool) -> Void)?
    private var progress : ((Error?, Float?) -> Void)?

    var filePath:URL {
        get{
            let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentDirectoryPath:String = path[0]
            let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/node.bin"))
            return destinationURLForFile
        }
    }
    
    var isNeedReturnToRestore:Bool {
        get {
            return (FileManager.default.fileExists(atPath: filePath.path))
        }
    }
    
    public func cancelRestore() {
        BackgroundDownloader.shared.cancelDownloading()
        
        if FileManager.default.fileExists(atPath: filePath.path)
        {
            do {
                try FileManager.default.removeItem(at: filePath)
            }
            catch{
                print(error)
            }
        }
    }
    
    public func startRestore(completion:@escaping ((Bool) -> Void), progress:@escaping ((Error?, Float?) -> Void)) {
        
        self.cancelRestore()
        self.completion = completion
        self.progress = progress
        
        var url:URL?
        
        if Settings.sharedManager().target == Testnet {
            url = URL(string: "https://mobile-restore.beam.mw/testnet/testnet_recovery.bin")
        }
        
        if let downloadUrl = url {
            BackgroundDownloader.shared.startDownloading(downloadUrl, filePath)
            BackgroundDownloader.shared.onProgress = { (progress, error, filePath) in
                if filePath != nil {
                    self.completion?(true)
                }
                else{
                    self.progress?(error, progress)
                }
            }
        }
    }
}
