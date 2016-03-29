//
//  FileTableViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

struct FileTableColumnIdentifier {
    static let Document = "document"
    static let Created = "created"
    static let Updated = "updated"
    static let Tags = "tags"
}

class FileTableViewController: NSViewController, FileCollectionScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var tableView: NSTableView!

    // MARK: - File Collection Scene

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    var selectsOnDoubleClick: Bool = false
    var delegate: SelectionDelegate?
    
    dynamic var selectedObjects: [DataSource] = [] {
        didSet {
            if let delegate = delegate {
                delegate.object(self, didChangeSelection: selectedObjects)
            }
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table View
        
        tableView.target = self
        tableView.doubleAction = #selector(FileTableViewController.doubleClick(_:))
    }
    
    func willClose() {
    
    }
    
    // MARK: -
    
    func minimize() {
        guard viewLoaded else {
            return
        }
        
        let identifiers = [
            FileTableColumnIdentifier.Created,
            FileTableColumnIdentifier.Updated,
            FileTableColumnIdentifier.Tags,
        ]
        
        for id in identifiers {
            tableView.tableColumnWithIdentifier(id)?.hidden = true
        }
    }
    
    func maximize() {
        guard viewLoaded else {
            return
        }
        
        let identifiers = [
            FileTableColumnIdentifier.Created,
            FileTableColumnIdentifier.Updated,
            FileTableColumnIdentifier.Tags,
        ]
        
        for id in identifiers {
            tableView.tableColumnWithIdentifier(id)?.hidden = false
        }
    }
    
    // MARK: -
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard selectsOnDoubleClick else {
            return
        }
        guard arrayController.selectedObjects.count > 0 else {
            return
        }
        
        selectedObjects = arrayController.selectedObjects as! [DataSource]
    }
    
    override func deleteBackward(sender: AnyObject?) {
        log("deleteBackward")
    }
    
    override func insertNewline(sender: AnyObject?) {
        log("insertNewline")
        doubleClick(sender)
    }
    
    override func quickLookPreviewItems(sender: AnyObject?) {
        log("quickLookPreviewItems")
    }
}

extension FileTableViewController: NSTableViewDelegate {
    
    func tableView(tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        if let view = tableView.makeViewWithIdentifier("RowView", owner: self) as? TableRowView {
            return view
        } else {
            let view = TableRowView()
            view.identifier = "RowView"
            return view
        }
    }
    
    func tableViewSelectionDidChange(notification: NSNotification) {
        guard let selection = arrayController.selectedObjects as? [DataSource] else {
            return
        }
        
        selectedObjects = selection
    }
}
