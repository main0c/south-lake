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
    @IBOutlet var tagsArrayController: NSArrayController!
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
            scene?.databaseManager = databaseManager
            bindLibrary()
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
            scene?.searchService = searchService
        }
    }
    
    // TODO: make selectedObjects an inspector protocol property?
    
    dynamic var selectedObjects: [DataSource] = []
    
    // MARK: - Custom Properties
    
    var tags: [String]?
    var scene: LibraryScene?
    
    dynamic var libraryContent: [DataSource] = []
    dynamic var selectedTags: [String]? {
        didSet {
            guard let selectedTags = selectedTags,
                  let selectedTag = selectedTags[safe: 0] else {
                  libraryArrayController.filterPredicate = NSPredicate(value: false)
                  return
            }
            
            let ids = selectedObjects.map { $0.document!.documentID }
            libraryArrayController.filterPredicate = NSPredicate(format: "%@ in tags && !(id in %@)", selectedTag, ids)
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        tagsArrayController.sortDescriptors = [NSSortDescriptor(key: "self", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        libraryArrayController.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: Selector("compare:"))]
        
        loadScene("libraryCollectionScene")
        
        bind("selectedTags", toObject: tagsArrayController, withKeyPath: "selectedObjects", options: [:])
        bindLibrary()
    }
    
    deinit {
        unbind("libraryContent")
        unbind("selectedTags")
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
        guard var scene = scene else {
            print("unable to load scene")
            return
        }
        
        // Databasable
        
        scene.databaseManager = databaseManager
        scene.searchService = searchService
        
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
        guard let scene = scene else {
            return
        }
        
        scene.arrayController.unbind("contentArray")
        scene.view.removeFromSuperview()
    }

}
