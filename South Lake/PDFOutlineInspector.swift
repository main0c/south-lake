//
//  PDFOutlineInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class PDFOutlineInspector: NSViewController, Inspector {

    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named:"pdf-table-of-contents-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named:"pdf-table-of-contents-selected-icon")!
    }
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}
