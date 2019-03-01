//
//  Configurable.swift
//  BeamWallet
//
//  Created by Denis on 3/1/19.
//  Copyright © 2019 Denis. All rights reserved.
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
    
    associatedtype ContentModel
    
    static func height(with contentModel: ContentModel, constrainedWidth width: CGFloat) -> CGFloat
}
