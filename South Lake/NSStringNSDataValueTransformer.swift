//
//  NSStringNSDataValueTransformer.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(NSStringNSDataValueTransformer)
class NSStringNSDataValueTransformer: NSValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSData.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        if let string = value as? NSString {
            return string.dataUsingEncoding(NSUTF8StringEncoding)
        } else {
            return nil
        }
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let data = value as? NSData {
            return NSString(data: data, encoding: NSUTF8StringEncoding)
        } else {
            return nil
        }
    }
}
