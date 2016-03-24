//
//  FileTableViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class FileTableViewController: NSViewController, FileCollectionScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var tableView: NSTableView!

    // MARK: - Databasable

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.target = self
        tableView.doubleAction = Selector("doubleClick:")
    }
    
    func willClose() {
        
    }
       
    @IBAction func doubleClick(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        guard let object = arrayController.selectedObjects[safe: 0] as? DataSource,
              let id = object.id else {
            print("no selected object")
            return
        }
        guard let url = NSURL(string: "southlake://localhost/library/\(id)") else {
            print("unable to construct url for object with id \(id)")
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "source": object,
            "url": url
        ])
    }
    
    override func deleteBackward(sender: AnyObject?) {
        print("deleteBackward")
    }
    
    override func insertNewline(sender: AnyObject?) {
        print("insertNewline")
        doubleClick(sender)
    }
    
    override func quickLookPreviewItems(sender: AnyObject?) {
        print("quickLookPreviewItems")
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
