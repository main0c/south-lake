//
//  DataSourceEditableValueTransformer.swift
//  South Lake
//
//  Created by Philip Dow on 3/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(DataSourceEditableValueTransformer)
class DataSourceEditableValueTransformer: NSValueTransformer {
    
    static let types = [
        DataTypes.Library.uti,
        DataTypes.Calendar.uti,
        DataTypes.Tags.uti,
        DataTypes.Trash.uti
    ]
    
    override class func allowsReverseTransformation() -> Bool {
        return false
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSNumber.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        if let value = value as? String {
            return !DataSourceEditableValueTransformer.types.contains(value)
        } else {
            return true
        }
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let data = value as? NSData {
            return NSString(data: data, encoding: NSUTF8StringEncoding)
        } else {
            return "" // nil
        }
    }
}
