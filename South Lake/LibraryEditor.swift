//
//  LibraryEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class LibraryEditor: NSViewController, FileEditor {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"] }
    static var storyboard: String { return "LibraryEditor" }
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    var isFileEditor: Bool {
        return false
    }
    
    dynamic var file: DataSource? {
        didSet {
            loadLibrary()
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        return nil
    }
    
    // MARK: - Custom Properties
    
    dynamic var sortDescriptors: [NSSortDescriptor]?
    dynamic var filterPredicate: NSPredicate?
    dynamic var content: [DataSource]?
    
    var liveQuery: CBLLiveQuery! {
        willSet {
            if let query = liveQuery {
                query.removeObserver(self, forKeyPath: "rows")
            }
        }
    }
    
    var scene: LibraryScene!

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: Selector("compare:"))]
        
        // TODO: Save and restore scene preference
        
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
        
        content = files
    }
    
    // MARK: - User Actions
    
    @IBAction func filterByTitle(sender: AnyObject?) {
        guard let sender = sender as? NSSearchField else {
            return
        }
        
        let text = sender.stringValue
        filterPredicate = ( text == "" ) ? nil : NSPredicate(format: "title contains[cd] %@", text)
    }
    
    @IBAction func sortByProperty(sender: AnyObject?) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        
        var descriptors = arrayController.sortDescriptors
        let key = descriptors.count != 0 ? descriptors[0].key : nil
        
        // Selecting the same item twice reverses the sort
        // But by default show most recent files first
        
        switch sender.tag {
        case 1001: // by title
            descriptors = [NSSortDescriptor(key: "title", ascending: key != "title", selector: Selector("caseInsensitiveCompare:"))]
        case 1002: // by date created
            descriptors = [NSSortDescriptor(key: "created_at", ascending: !(key != "created_at"), selector: Selector("compare:"))]
        case 1003: // by date updated
            descriptors = [NSSortDescriptor(key: "updated_at", ascending: !(key != "updated_at"), selector: Selector("compare:"))]
        default:
            break
        }
        
        arrayController.sortDescriptors = descriptors
    }
    
    @IBAction func changeScene(sender: AnyObject?) {
        guard let sender = sender as? NSSegmentedControl,
              let cell = sender.cell as? NSSegmentedCell else {
              return
        }
        
        let segment = sender.selectedSegment
        let tag = cell.tagForSegment(segment)
        
        switch tag {
        case 0: // icon collection
            unloadScene()
            loadScene("libraryCollectionScene")
        case 1: // table view
            unloadScene()
            loadScene("libraryTableScene")
        case _:
            break
        }
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
        
        scene.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
    }
    
    func unloadScene() {
        guard (scene as LibraryScene?) != nil else {
            return
        }
        
        scene.arrayController.unbind("contentArray")
        scene.view.removeFromSuperview()
    }
}

