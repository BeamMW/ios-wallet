//
// CrowdinManager.swift
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

class CrowdinManager : NSObject {
    
   fileprivate static var zipPath:URL {
        get{
            let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentDirectoryPath:String = path[0]
            let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/all.zip"))
            return destinationURLForFile
        }
    }
    
    static var localizationPath:URL {
        get{
            let path = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true)
            let documentDirectoryPath:String = path[0]
            let destinationURLForFile = URL(fileURLWithPath: documentDirectoryPath.appendingFormat("/localization"))
            return destinationURLForFile
        }
    }
    
    static public func updateLocalizations() {
        let zipLink = URL(string: "https://api.crowdin.com/api/project/\(crowdinProject)/download/all.zip?key=\(crowdinKey)")!
        
        BackgroundDownloader.shared.startDownloading(zipLink, zipPath)
        BackgroundDownloader.shared.onProgress = { (progress, error, filePath) in
            if filePath != nil {
                
                if FileManager.default.fileExists(atPath: localizationPath.path)
                {
                    do {
                        try FileManager.default.removeItem(at: localizationPath)
                    }
                    catch{
                        print(error)
                    }
                }
                
                SSZipArchive.unzipFile(atPath: filePath!, toDestination: localizationPath.path, overwrite:true, password: nil, progressHandler: { (_ , _ , _ , _ ) in
                
                }, completionHandler: { (path, success, error ) in
                    if(success) {
                        do {
                            let items = try FileManager.default.contentsOfDirectory(atPath: localizationPath.path)
                            
                            for item in items {
                                if item == "zh-CN" {
                                    try? FileManager.default.moveItem(at: localizationPath.appendingPathComponent(item), to: localizationPath.appendingPathComponent("zh-Hans"))

                                }
                                else if item == "es-ES" {
                                    try? FileManager.default.moveItem(at: localizationPath.appendingPathComponent(item), to: localizationPath.appendingPathComponent("es"))
                                }
                            }
                        } catch {
                            print(error)
                        }
                        
                        Localizable.shared.reset()
                    }
                })
            }
        }
    }
}

