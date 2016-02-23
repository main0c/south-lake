//
//  ImporterExtensions.swift
//  South Lake
//
//  Created by Philip Dow on 2/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class ImporterExtensions: NSObject {
    private var importers: [String] = []
    
    func registerExtensions() {
    
    }
    
    func importerForFiletype(filetype: String) -> AnyObject? {
        return nil
    }
}
