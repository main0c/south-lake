//
//  RelatedInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class RelatedInspector: NSViewController, Inspector {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    
    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "related-files-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named: "related-files-selected-icon")!
    }
    
    var databaseManager: DatabaseManager! {
        didSet {
            loadData()
        }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    // MARK: - Custom Properties
    
    // TODO: is selectedObjects an inspector protocol property?
    
    dynamic var selectedObjects: [DataSource] = []
    
    dynamic var tagsContent: [[String:AnyObject]] = []
    
    var liveQuery: CBLLiveQuery! {
        willSet {
            if let query = liveQuery {
                query.removeObserver(self, forKeyPath: "rows")
            }
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        arrayController.sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        arrayController.bind("contentArray", toObject: self, withKeyPath: "selectedObjects", options: [:])
    
        loadData()
    }
    
    deinit {
        liveQuery.removeObserver(self, forKeyPath: "rows")
        liveQuery.stop()
    }
    
    // MARK: - Tags Data
    
    func loadData() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        let query = databaseManager.tagsQuery
        query.groupLevel = 1
        
        liveQuery = query.asLiveQuery()
        liveQuery.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        liveQuery.start()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object as? NSObject == liveQuery {
            displayRows(liveQuery.rows)
        }
    }
    
    func displayRows(results: CBLQueryEnumerator?) {
        guard let results = results else {
            return
        }
        
        var tags: [[String:AnyObject]] = []
        
        while let row = results.nextRow() {
            let count = row.value as! Int
            let tag = row.key as! String
            
            tags.append([
                "tag": tag,
                "count": count
            ])
        }
        
        tagsContent = tags
    }
}
