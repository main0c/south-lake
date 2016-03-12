//
//  RelatedInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class RelatedInspector: NSViewController, Inspector {
    @IBOutlet var sourceArrayController: NSArrayController!
    @IBOutlet var libraryArrayController: NSArrayController!
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
            loadLibrary()
        }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    // TODO: is selectedObjects an inspector protocol property?
    
    dynamic var selectedObjects: [DataSource] = [] {
        didSet {
            selectedTag = ( selectedObjects.count > 0 ) ?
                ((selectedObjects as NSArray).valueForKeyPath("@distinctUnionOfArrays.tags") as! Array)[safe: 0]
                : nil
        }
    }
    
    // MARK: - Custom Properties
    
    var scene: LibraryScene!
    
    dynamic var libraryContent: [DataSource] = []
    dynamic var libraryFilterPredicate: NSPredicate?
    
    dynamic var selectedTag: String? {
        didSet {
            guard selectedTag != nil && selectedTag != "" else {
                libraryFilterPredicate = NSPredicate(value: false)
                return
            }
            libraryFilterPredicate = NSPredicate(format: "%@ in tags", selectedTag!)
        }
    }
    
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
        
        // TODO: move to IB?
        
        sourceArrayController.sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        sourceArrayController.bind("contentArray", toObject: self, withKeyPath: "selectedObjects", options: [:])
        
        libraryArrayController.bind("contentArray", toObject: self, withKeyPath: "libraryContent", options: [:])
        
        libraryArrayController.bind("filterPredicate", toObject: self, withKeyPath: "libraryFilterPredicate", options: [:])
    
        loadScene("libraryCollectionScene")
        loadLibrary()
    }
    
    deinit {
        liveQuery.removeObserver(self, forKeyPath: "rows")
        liveQuery.stop()
    }
    
    // MARK: - Library Data
    
    func loadLibrary() {        
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        let query = databaseManager.fileQuery

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
        
        var files: [File] = []
            
        while let row = results.nextRow() {
            if let document = row.document {
                let file = CBLModel(forDocument: document) as! File
                files.append(file)
            }
        }
        
        libraryContent = files
    }
    
    // MARK: - Utilities
    
    func loadScene(identifier: String) {
        scene = storyboard!.instantiateControllerWithIdentifier(identifier) as! LibraryScene
        
        // Set up frame and view constraints
        
        scene.view.translatesAutoresizingMaskIntoConstraints = false
        scene.view.frame = containerView.bounds
        containerView.addSubview(scene.view)
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": scene.view])
        )
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": scene.view])
        )
        
        // Bind the array controller to ours
        // Predicates and sorting are applied before it even sees the data
        
        scene.arrayController.bind("contentArray", toObject: libraryArrayController, withKeyPath: "arrangedObjects", options: [:])
    }
    
    func unloadScene() {
        guard (scene as LibraryScene?) != nil else {
            return
        }
        
        scene.arrayController.unbind("contentArray")
        scene.view.removeFromSuperview()
    }

}
