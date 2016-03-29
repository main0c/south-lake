//
//  RelatedInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: factor library editor scenes. used here and in the tags editor

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
    
    var databaseManager: DatabaseManager? {
        didSet {
            scene?.databaseManager = databaseManager
            bindLibrary()
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            scene?.searchService = searchService
        }
    }
    
    // TODO: make selectedObjects an inspector protocol property?
    
    dynamic var selectedObjects: [DataSource] = []
    
    // MARK: - Custom Properties
    
    var tags: [String]?
    var scene: FileCollectionScene?
    
    dynamic var libraryContent: [DataSource] = []
    dynamic var selectedTags: [String]? {
        didSet {
            guard let selectedTag = selectedTags?[safe: 0] else {
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
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.Inspector
        
        tagsArrayController.sortDescriptors = [NSSortDescriptor(key: "self", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))]

        libraryArrayController.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: #selector(NSNumber.compare(_:)))]
        
        loadScene("FileCardView")
        
        bind("selectedTags", toObject: tagsArrayController, withKeyPath: "selectedObjects", options: [:])
        bindLibrary()
    }
    
    func willClose() {
        unbind("libraryContent")
        unbind("selectedTags")
    }
    
    // MARK: - Library Data
    
    func bindLibrary() {
        guard let databaseManager = databaseManager else {
            return
        }
        guard unbound("libraryContent") else {
            return
        }
        
        bind("libraryContent", toObject: databaseManager, withKeyPath: "files", options: [:])
    }
    
    // MARK: - Utilities
    
    func loadScene(identifier: String) {
        scene = storyboard!.instantiateControllerWithIdentifier(identifier) as? FileCollectionScene
        guard var scene = scene else {
            log("unable to load scene")
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
        
        // Custom background colors - would prefer to do this another way
        // Simple setBackgroundColor() on FileCollectionScene for example
        
        if let tagsScene = scene as? FileCardViewController {
            tagsScene.collectionView.backgroundColors = [UI.Color.Background.Inspector]
        }
        
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

    // MARK: - User Actions
    
    @IBAction func seeMore(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        guard let selectedTag = selectedTags?[safe: 0],
              let encodedTag = selectedTag.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
              return
        }
        guard let url = NSURL(string: "southlake://localhost/tags/\(encodedTag)") else {
            log("unable to construct url for tag \(selectedTag)")
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "url": url
        ])
    }
    
}
