//
//  TwoWayKeyValueObserving.swift
//  South Lake
//
//  Created by Philip Dow on 2/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

private var KeyValueObservingProxyContext = 0

protocol TwoWayKeyValueObserving {
    func bindUs(binding: String, toObject: AnyObject, withKeyPath: String, options: [String : AnyObject]?)
    func unbindUs(binding: String, toObject: AnyObject, withKeyPath: String)
    func areBound(binding: String, toObject: AnyObject, withKeyPath: String) -> Bool
}

// Default implementation

extension NSObject: TwoWayKeyValueObserving {
    private struct AssociatedKeys {
        static var kvo = "kvoProxies"
    }
    
    private var kvoProxies: Dictionary<String,AnyObject>? {
        get {
            guard let dict = objc_getAssociatedObject(self, &AssociatedKeys.kvo)
                      as? Dictionary<String,AnyObject> else {
                return nil
            }
            return dict
        }
        set(value) {
            objc_setAssociatedObject(self, &AssociatedKeys.kvo, value, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        }
    }
    
    private func bindUsKey(binding: String, toObject: AnyObject, withKeyPath: String) -> String {
        return "\(unsafeAddressOf(self)):\(binding):\(unsafeAddressOf(toObject)):\(withKeyPath)"
    }
    
    func bindUs(binding: String, toObject: AnyObject, withKeyPath: String, options: [String : AnyObject]?) {
        
        // Self notifies proxy when "binding" changes
        // ToObject notifies proxy when "withKeyPath" changes
        
        // Documentation:
        // Neither the receiver, nor anObserver, are retained.
        // An object that calls this method must also call either the removeObserver:forKeyPath: or removeObserver:forKeyPath:context: method when participating in KVO.
        
        // Proxy still has to be keyed to the receiver-binding-toObject-withKeyPath
        // So store a (mutable) dictionary of proxies with help of unsafeAddressOf
        
        let key = bindUsKey(binding, toObject: toObject, withKeyPath: withKeyPath)
        var proxies = kvoProxies ?? Dictionary()
        
        guard proxies[key] == nil else {
            print("objects are already bound with these keys")
            return
        }
        
        let proxy = KeyValueObservingProxy(receiver: self, receiverKey: binding, toObject: toObject, toObjectKey: withKeyPath)
        
        self.addObserver(proxy, forKeyPath: binding, options: [.New, .Old], context: &KeyValueObservingProxyContext)
                
        toObject.addObserver(proxy, forKeyPath: withKeyPath, options: [.New, .Old], context:&KeyValueObservingProxyContext)
        
        proxies[key] = proxy
        kvoProxies = proxies
    }
    
    func unbindUs(binding: String, toObject: AnyObject, withKeyPath: String) {
        let key = bindUsKey(binding, toObject: toObject, withKeyPath: withKeyPath)
        
        guard var proxies = kvoProxies else {
            print("no proxies registered")
            return
        }
        
        guard let proxy = proxies[key] as? KeyValueObservingProxy else {
            print("no proxy for these these objects and keys")
            return
        }
        
        self.removeObserver(proxy, forKeyPath: binding)
        toObject.removeObserver(proxy, forKeyPath: withKeyPath)
        
        proxies[key] = nil
        kvoProxies = proxies
    }
    
    func areBound(binding: String, toObject: AnyObject, withKeyPath: String) -> Bool {
        let key = bindUsKey(binding, toObject: toObject, withKeyPath: withKeyPath)
        
        guard let proxies = kvoProxies else {
            return false
        }
        
        return proxies[key] != nil
    }
}

class KeyValueObservingProxy: NSObject {
    
    // Proxy must keep track of the objects it's observing
    
    weak var receiver: AnyObject?
    weak var toObject: AnyObject?
    
    var receiverKey: String
    var toObjectKey: String
    
    // Updating is simple state to prevent a KVO loop, but it won't work if a
    // setter internally transforms its value and then re-sets it.
    
    // How does those OS do this with two-way XIB bindings?
    
    private var updating: Bool = false
    
    init(receiver: AnyObject, receiverKey: String, toObject: AnyObject, toObjectKey: String) {
        self.receiver = receiver
        self.toObject = toObject
        self.receiverKey = receiverKey
        self.toObjectKey = toObjectKey
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        // Ensure this proxy isn't already updating one way
        
        guard !updating else {
            return
        }
        
        // Ensure we have something to update
        
        guard let change = change, let newValue = change[NSKeyValueChangeNewKey] else {
            print("observer proxy didn't receive new value")
            return
        }
        
        // Inform the interested parties
        
        updating = true
        
        if object === receiver {
            toObject!.setValue(newValue, forKey: toObjectKey)
        } else if object === toObject {
            receiver!.setValue(newValue, forKey: receiverKey)
        } else {
            print("object !== receiver and object !== toObject")
        }
        
        updating = false
    }
}
