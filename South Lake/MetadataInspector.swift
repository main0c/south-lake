//
//  MetadataInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class MetadataInspector: NSViewController, Inspector {
    @IBOutlet var tableView: NSTableView!
    
    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "metadata-icon")!
    }
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // tableView.usesStaticContents = true // if only
    }
    
}

// MARK: - NSTableViewDataSource

extension MetadataInspector: NSTableViewDataSource {
    
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return 1
    }
}

// MARK: - NSTableViewDelegate

extension MetadataInspector: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        
        return tableView.makeViewWithIdentifier("FileInfo", owner: self) as! NSTableCellView
    }
    
    func tableView(tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 72
    }
}