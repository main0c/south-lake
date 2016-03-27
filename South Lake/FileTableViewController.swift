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

    // MARK: - Databasable

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // MARK: - Custom
    
    dynamic var selectedObjects: [DataSource]?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Table View
        
        tableView.target = self
        tableView.doubleAction = Selector("doubleClick:")
        
        // Array Controller
        
        bind("selectedObjects", toObject: arrayController, withKeyPath: "selectedObjects", options: [:])
    }
    
    func willClose() {
        unbind("selectedObjects")
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
        guard let databaseManager = databaseManager else {
            return
        }
        guard let object = arrayController.selectedObjects[safe: 0] as? DataSource,
              let id = object.id else {
            log("no selected object")
            return
        }
        guard let url = NSURL(string: "southlake://localhost/library/\(id)") else {
            log("unable to construct url for object with id \(id)")
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "source": object,
            "url": url
        ])
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
}
