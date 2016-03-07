//
//  TagsValueTransformer.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(TagsValueTransformer)
class TagsValueTransformer: NSValueTransformer {
    override class func allowsReverseTransformation() -> Bool {
        return true
    }
    
    override class func transformedValueClass() -> AnyClass {
        return NSString.self
    }
    
    override func transformedValue(value: AnyObject?) -> AnyObject? {
        if let array = value as? [String] {
            return array.joinWithSeparator(", ")
        } else {
            return "" // nil
        }
    }
    
    override func reverseTransformedValue(value: AnyObject?) -> AnyObject? {
        if let string = value as? String {
            return string.characters.split{ $0 == "," }.map(String.init).map { $0.trim() }
        } else {
            return [] // nil
        }
    }
}

extension String {
    func trim() -> String {
        return self.stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceCharacterSet())
    }
}
