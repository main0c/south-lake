//
//  MarkdownImporter.swift
//  South Lake
//
//  Created by Philip Dow on 2/25/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  An importer needs to be able to handle file imports, but eventually it may
//  also need to handle pasteboard imports?

import Foundation

@objc(MarkdownImporter)
class MarkdownImporter: NSObject, FileImporter {
    static var filetypes: [String] = ["net.daringfireball.markdown", "markdown", "text/markdown"]
    
    override required init() {
        super.init()
    }
    
    func plainTextRepresentation(data: NSData?) -> String? {
        guard let data = data else {
            return nil
        }
        guard let text = String(data: data, encoding: NSUTF8StringEncoding) else {
            log("unable to derive markdown string from data")
            return nil
        }
        
        return text
    }
    
    func thumbnail(data: NSData?) -> NSImage? {
        return nil
    }
}