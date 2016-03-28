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
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        thumbnailView.setBackgroundColor(UI.Color.Background.Inspector)
    }
    
    func willClose() {
    
    }
}
