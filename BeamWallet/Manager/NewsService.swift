//
// NewsService.swift
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
import SwiftSoup

class NewsService {
    static func loadNews() {
        let url = URL(string: "https://www.beam.mw/news")!
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        let request = URLRequest(url: url)
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                let html = String(data: data, encoding: String.Encoding.utf8)!
                let doc: Document = try SwiftSoup.parse(html)
                let link = try doc.body()?.select("news content-item")
                print(try link?.text())
                print(try link?.outerHtml())
            } catch Exception.Error(let type, let message) {
                print(message)
            } catch {
                print("error")
            }
        })
        
        task.resume()
    }
}
