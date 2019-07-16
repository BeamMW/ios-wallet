//
// BackgroundDownloader.swift
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

class BackgroundDownloader: NSObject {

    typealias ProgressHandler = (Float?,Error?, String?) -> ()

    var onProgress : ProgressHandler?
    
    static var shared = BackgroundDownloader()

    private var destinationURLForFile:URL!
    private var task:URLSessionDownloadTask?
    
    private var start = Date.timeIntervalSinceReferenceDate;

    public func startDownloading(_ url:URL, _ destinationUrl:URL) {
        
        if FileManager.default.fileExists(atPath: destinationUrl.path)
        {
            do {
                try FileManager.default.removeItem(at: destinationUrl)
            }
            catch{
                print(error)
            }
        }
        
        self.destinationURLForFile =  destinationUrl
        
        let config = URLSessionConfiguration.background(withIdentifier: "com.beam.background" + url.lastPathComponent)

        let session = URLSession(configuration: config, delegate: self, delegateQueue: OperationQueue())

        start = Date.timeIntervalSinceReferenceDate

        task = session.downloadTask(with: url)
        task?.resume()
    }
    
    public func cancelDownloading() {
        task?.cancel()
    }
}

extension BackgroundDownloader: URLSessionTaskDelegate, URLSessionDownloadDelegate {
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        if totalBytesExpectedToWrite > 0 {
            
            let progress = Float(totalBytesWritten) / Float(totalBytesExpectedToWrite)
         //   print("Progress \(downloadTask) \(progress)")
            onProgress?(progress, nil, nil)
            
            let speed = Double(totalBytesWritten) / Double((Date.timeIntervalSinceReferenceDate - self.start))
            
            if speed > 0 {
                let sizeLeft = Double(totalBytesExpectedToWrite-totalBytesWritten)
                let timeLeft = sizeLeft / speed
                
                print("-----------")
                print(timeLeft.asTime(style: .abbreviated))
                print("-----------")
            }
        }
    }
    
    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        print("Download finished: \(location)")
        
        do {
            try FileManager.default.moveItem(at: location, to: destinationURLForFile)
            onProgress?(nil, nil, destinationURLForFile.path)
            
        }catch{
            onProgress?(nil, error, nil)
        }
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        if let reason = error {
            let code = (reason as NSError).code
            if code != -999 {
                onProgress?(nil, reason, nil)
            }
        }
    }
}
