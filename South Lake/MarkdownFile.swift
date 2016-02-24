//
//  MarkdownFile.swift
//  South Lake
//
//  Created by Philip Dow on 2/23/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

// These classes all go together, though not necessarily: 
// File, Editor, Importer

// Markdown is "built in" so it doesn't require an importer, unless you're importing markdown
// A model class doesn't have to have a corresponding editor, because we can use a generic editor 

import Foundation

@objc(MarkdownFile)
class MarkdownFile: File {
    override class var model_file_extension: NSString { return "markdown" }
    override class var model_mime_type: NSString { return "text/markdown" }
    override class var model_uti: NSString { return "net.daringfireball.markdown" }
    
    override func updatePlainText(data: NSData?) {
        guard let data = data else {
            plain_text = ""
            return
        }
        
        guard let text = String(data: data, encoding: NSUTF8StringEncoding) else {
            print("unable to drive markdown string from data")
            return
        }
        
        plain_text = text
    }
}