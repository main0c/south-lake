//
//  RelatedInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class RelatedInspector: NSViewController, Inspector {

    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "related-files-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named: "related-files-selected-icon")!
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
