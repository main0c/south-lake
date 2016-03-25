//
//  NSURL+FileType.swift
//  South Lake
//
//  Created by Philip Dow on 2/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Source: https://github.com/cockscomb/UTIKit

import Foundation

extension NSURL {
    var UTI: String? {
        guard fileURL else {
            return nil
        }
        
        do {
            var typeIdentifier: AnyObject?
            try getResourceValue(&typeIdentifier, forKey: NSURLTypeIdentifierKey)
            return typeIdentifier as? String ?? nil
        } catch {
            log(error)
            return nil
        }
    }
    
    var mimeType: String? {
        guard fileURL else {
            return nil
        }
        
        if let uti = UTI {
            return UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() as String?
        } else {
            return nil
        }
    }
    
    var fileExtension: String? {
        guard fileURL else {
            return nil
        }
        
        return pathExtension
    }
}