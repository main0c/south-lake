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
            bindLibrary()
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
            
            let ids = selectedObjects.map { $0.document!.documentID }
            libraryFilterPredicate = NSPredicate(format: "%@ in tags && !(document.documentID in %@)", selectedTag!, ids)
        }
    }
  
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        // TODO: move to IB?
        // TODO: would rather have a tags controller than a source controller that extracts
        //       the tags from the source. the popup binds to that rather than doing the
        //       transformation itself
        
        sourceArrayController.sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        sourceArrayController.bind("contentArray", toObject: self, withKeyPath: "selectedObjects", options: [:])
        
        libraryArrayController.bind("contentArray", toObject: self, withKeyPath: "libraryContent", options: [:])
        
        libraryArrayController.bind("filterPredicate", toObject: self, withKeyPath: "libraryFilterPredicate", options: [:])
        
        libraryArrayController.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: Selector("compare:"))]
    
        loadScene("libraryCollectionScene")
        bindLibrary()
    }
    
    deinit {
        unbind("libraryContent")
    }
    
    // MARK: - Library Data
    
    func bindLibrary() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        bind("libraryContent", toObject: databaseManager, withKeyPath: "files", options: [:])
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
