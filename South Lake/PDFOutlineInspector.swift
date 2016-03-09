//
//  PDFOutlineInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class PDFOutlineInspector: NSViewController, Inspector {

    var icon: NSImage {
        return NSImage(named:"pdf-thumbnails-icon")!
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
    }
    
}
