//
//  FileListViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/23/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class FileListViewController: NSViewController {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - File Collection Scene

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?

    dynamic var selectedObjects: [DataSource]?
    var selectsOnDoubleClick: Bool = false {
        didSet {
            if selectsOnDoubleClick {
                unbind("selectedObjects")
            } else {
                bind("selectedObjects", toObject: arrayController, withKeyPath: "selectedObjects", options: [:])
            }
        }
    }
    
    // MARK: - Initialiation

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: -
    
    func minimize() {
    
    }
    
    func maximize() {
    
    }
    
    // MARK:
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard arrayController.selectedObjects.count > 0 else {
            return
        }
        
        selectedObjects = arrayController.selectedObjects as? [DataSource]
    }
    
}
