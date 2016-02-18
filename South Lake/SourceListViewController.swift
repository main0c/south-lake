//
//  SourceListViewController.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class SourceListViewController: NSViewController {
    @IBOutlet var outlineView: NSOutlineView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func createNewFolder(sender: AnyObject) {
        // Create an untitled folder
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject) {
        // Create an untitled smart folder
    }
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject) {
        // Create an untitled document
    }
    
    @IBAction func userDidEndEditingCell(sender: NSTextField) {
        // Update data source title
    }
}

extension SourceListViewController : NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        return 0
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        return self
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        return false
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        return nil
    }
}