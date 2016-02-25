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

// Perhaps some kind of generic Extensions Manager is needed that knows how to 
// load these things given a path, and then can return an object

// How do I allow 3rd parties to subclass File (or implement a protocol) without
// including File or the protocol in the bundle?

// Answer 1: Use a "core" framework - major rearchitecture
// http://stackoverflow.com/questions/6824213/cocoa-loading-a-bundle-in-which-some-classes-inherit-from-a-custom-framework
// https://mikeash.com/pyblog/friday-qa-2009-11-06-linking-and-install-names.html

// Can I weakly link a class instead of a whole framework? Symbols anyway...

// Answer 2: Use an interpreted language. Totally not an issue when you can guarantee
// that the interpreter has loaded superclass information before the subclasses

// Answer 3: Use protocols instead of subclasses. I wonder if protocol symbols are linked into
// the binary and will cause any conflicts.

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
            print("unable to derive markdown string from data")
            return
        }
        
        plain_text = text
    }
}