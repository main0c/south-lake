//
//  ImporterPlugIns.swift
//  South Lake
//
//  Created by Philip Dow on 2/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Eventually this manages bundles with a principle class

import Cocoa

class ImporterPlugIns {
    static let sharedInstance = ImporterPlugIns()
    private var plugins: [ [String:AnyObject] ] = []
    
    private init() {
        self.registerPlugIns()
    }
    
    func registerPlugIns() {
        // Store this information in a bundle plist
        // Just need the bundle, storyboard name and filetypes
        
        plugins = [
            [
                "filetypes": ["net.daringfireball.markdown", "markdown", "text/markdown"],
                "classname": "MarkdownImporter"
            ],
            [
                "filetypes": ["com.adobe.pdf", "pdf", "application/pdf"],
                "classname": "PDFImporter"
            ]
        ]
    }
    
    func plugInForFiletype(filetype: String) -> FileImporter? {
        var classname: String?
        
        for plugin in plugins {
            guard let filetypes = plugin["filetypes"] as? [String],
                  let cn = plugin["classname"] as? String else {
                  continue
            }
            
            if filetypes.contains(filetype) {
                classname = cn
                break
            }
        }
        
        guard classname != nil else {
            return nil
        }
        
        if  let Class = NSClassFromString(classname!) as? FileImporter.Type,
            let instance: FileImporter = Class.init() {
            return instance
        } else {
            print("unable to instantiate importer")
            return nil
        }
    }
}
