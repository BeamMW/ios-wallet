//
// Configurable.swift
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
import CoreGraphics

protocol Configurable: class {
    
    associatedtype Configurator
    
    func configure(with configurator: Configurator)
}

extension Configurable {
    
    func configured(with configurator: Configurator) -> Self {
        
        self.configure(with: configurator)
        
        return self
    }
    
    func configured<Object>(with object: Object, configuration: ((Self, Object) -> Void)) -> Self {
        
        configuration(self, object)
        
        return self
    }
}

protocol Delegating: class {
    
    associatedtype Delegate
    
    var delegate: Delegate? { get set }
}

extension Delegating {
    
    func withDelegate(_ delegate: Delegate?) -> Self {
        
        self.delegate = delegate
        
        return self
    }
}

extension Configurable where Self: Delegating {
    
    func configure(with configurator: Configurator, delegate: Delegate?) {
        self.configure(with: configurator)
        self.delegate = delegate
    }
    
    func configured(with configurator: Configurator, delegate: Delegate?) -> Self {
        self.configure(with: configurator, delegate: delegate)
        return self
    }
}

protocol DynamicContentHeight {
        
    static func height() -> CGFloat
}
