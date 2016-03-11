//
//  PDFThumbnailController.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import Quartz

class PDFThumbnailInspector: NSViewController, Inspector {
    @IBOutlet var thumbnailView: PDFThumbnailView!

    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named:"pdf-thumbnails-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named:"pdf-thumbnails-selected-icon")!
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
        // Do view setup here.

        thumbnailView.setBackgroundColor(NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0))
    }
    
}
