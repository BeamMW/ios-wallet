/*
 Copyright 2015 XWebView

 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this file except in compliance with the License.
 You may obtain a copy of the License at

 http://www.apache.org/licenses/LICENSE-2.0

 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
*/

import Foundation

@objc public protocol XWVScripting : AnyObject {
    @objc optional var channelIdentifier: String { get }
    @objc optional func rewriteStub(_ stub: String, forKey: String) -> String
    @objc optional func invokeDefaultMethod(withArguments args: [Any]!) -> Any!
    @objc optional func finalizeForScript()

    @objc optional static func scriptName(forKey key: UnsafePointer<Int8>) -> String?
    @objc optional static func scriptName(for selector: Selector) -> String?
    @objc optional static func isSelectorExcluded(fromScript selector: Selector) -> Bool
    @objc optional static func isKeyExcluded(fromScript name: UnsafePointer<Int8>) -> Bool
}
