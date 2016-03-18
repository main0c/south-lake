//
//  NSObject+NSKeyValueQuestioning.swift
//  South Lake
//
//  Created by Philip Dow on 3/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSObject {
    func bound(binding: String) -> Bool {
        return !unbound(binding)
    }
    
    func unbound(binding: String) -> Bool {
        return infoForBinding(binding) == nil
    }
    
    func bindIfUnbound(binding: String, toObject observable: AnyObject, withKeyPath keyPath: String, options: [String : AnyObject]?) {
        guard unbound(binding) else {
            return
        }
        
        bind(binding, toObject: observable, withKeyPath: keyPath, options: options)
    }
}