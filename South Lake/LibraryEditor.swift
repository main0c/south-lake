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
    @IBOutlet var searchLabel: NSTextField!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"] }
    static var storyboard: String { return "LibraryEditor" }
    
    var databaseManager: DatabaseManager!
    var searchService: BRSearchService!
    
    var isFileEditor: Bool {
        return false
    }
    
    dynamic var file: DataSource? {
        didSet {
            bindLibrary()
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
    dynamic var content: [DataSource]?

    dynamic var filterPredicate: NSPredicate?
    
    var titlePredicate: NSPredicate? {
        didSet {
            updateFilterPredicate()
        }
    }
    
    var searchPredicate: NSPredicate? {
        didSet {
            updateFilterPredicate()
        }
    }

    var scene: LibraryScene!

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: Selector("compare:"))]
        
        searchLabel.hidden = true
        
        // TODO: Save and restore scene preference
        
        loadScene("libraryCollectionScene")
        bindLibrary()
    }
    
    deinit {
        unbind("content")
    }
    
    // MARK: - Library Data
    
    func bindLibrary() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        bind("content", toObject: databaseManager, withKeyPath: "files", options: [:])
    }
    
    // MARK: - User Actions
    
    @IBAction func filterByTitle(sender: AnyObject?) {
        guard let sender = sender as? NSSearchField else {
            return
        }
        
        let text = sender.stringValue
        titlePredicate = ( text == "" ) ? nil : NSPredicate(format: "title contains[cd] %@", text)
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
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
        searchLabel.hidden = ( text == nil || text! == "" )
        
        guard let text = text else {
            searchPredicate = nil
            return
        }
        
        searchLabel.stringValue = String.localizedStringWithFormat(NSLocalizedString("Searching for \"%@\"",
            comment: "Title of find tab"),
            text)
        
        guard let results = results where results.count() != 0 else {
            print("no search results")
            return
        }
        
        // Map results to an array of document ids
        
        var ids: [String] = []
        
        results.iterateWithBlock { (index: UInt, result: BRSearchResult!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
             guard let _ = result.dictionaryRepresentation(),
                  var id = result.valueForField("id") as? String,
                  let _ = result.valueForField("t") as? String,
                  let _ = result.valueForField("v") as? String else {
                  return
            }
            
            // TODO: lucene doc id question mark prefix
            // The lucene search results return a document identifier beginning
            // with a question mark even though I am indexing using an identifier
            // that does not have one. What gives?
            
            if id[id.startIndex] == "?" {
                id = id.substringFromIndex(id.startIndex.advancedBy(1))
            }
            
            ids.append(id)
        }
        
        searchPredicate = NSPredicate(format: "document.documentID in %@", ids)
    }
    
    func updateFilterPredicate() {
        switch (titlePredicate, searchPredicate) {
        case(.Some(let p1), .Some(let p2)):
            filterPredicate = NSCompoundPredicate(andPredicateWithSubpredicates: [p1,p2])
        case(.Some(let p1), nil):
            filterPredicate = p1
        case(nil, .Some(let p2)):
            filterPredicate = p2
        case(nil, nil):
            filterPredicate = nil
        }
    }
    
    func willClose() {
    
    }
}

