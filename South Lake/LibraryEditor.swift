//
//  LibraryEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: factor library editor scenes. used here, tags editor and related inspector
//        probably means we move the view controllers to their own storyboards as well

import Cocoa

class LibraryEditor: NSViewController, FileEditor {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"] }
    static var storyboard: String { return "LibraryEditor" }
    
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
    
    var isFileEditor: Bool {
        return false
    }
    
    dynamic var file: DataSource?
    
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

    var scene: LibraryScene?

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: Selector("compare:"))]
        
        // pathControl.cursor = NSCursor.pointingHandCursor()
        pathControl.URL = NSURL(string: "southlake://localhost/library")
        pathControl.backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        updatePathControlAppearance()
        
        // TODO: Save and restore scene preference
        
        loadScene("libraryCollectionScene")
        bindLibrary()
    }
    
    func willClose() {
        unloadScene()
        unbind("content")
    }

    // MARK: - Library Data
    
    func bindLibrary() {
        guard let databaseManager = databaseManager else {
            return
        }
        guard unbound("content") else {
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
        titlePredicate = ( text == "" ) ? nil : NSPredicate(format: "title contains[cd] %@ || any tags like[cd] %@", text, String(format: "*%@*", text))
    }
    
    @IBAction func sortByProperty(sender: AnyObject?) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        
        // Selecting the same menu item reverses the sort
        
        var descriptors = arrayController.sortDescriptors
        let asc = descriptors[safe: 0]?.ascending ?? true
        let key = descriptors[safe: 0]?.key
        
        switch sender.tag {
        case 1001: // by title
            descriptors = [NSSortDescriptor(key: "title", ascending: (key == "title" ? !asc : true), selector: Selector("caseInsensitiveCompare:"))]
        case 1002: // by date created
            descriptors = [NSSortDescriptor(key: "created_at", ascending: (key == "created_at" ? !asc : false), selector: Selector("compare:"))]
        case 1003: // by date updated
            descriptors = [NSSortDescriptor(key: "updated_at", ascending: (key == "updated_at" ? !asc : false), selector: Selector("compare:"))]
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
    
    @IBAction func gotoPath(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        guard let sender = sender as? NSPathControl else {
            return
        }
        guard let url = sender.clickedPathComponentCell()?.URL else {
            return
        }
        
        // TODO: finish
        return
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "url": url
        ])
    }
    
    // MARK: - Scene
    
    func loadScene(identifier: String) {
        scene = storyboard!.instantiateControllerWithIdentifier(identifier) as? LibraryScene
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
        
        scene.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
    }
    
    func unloadScene() {
        guard let scene = scene else {
            return
        }
        
        scene.arrayController.unbind("contentArray")
        scene.arrayController.content = []
        scene.view.removeFromSuperview()
        scene.willClose()
    }
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
        updatePathControlWithSearch(text)
        
        guard let _ = text else {
            searchPredicate = nil
            return
        }
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
        
        searchPredicate = NSPredicate(format: "id in %@", ids)
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
    
    func openURL(url: NSURL) {
    
    }
    
    // MARK: - Utilities
    
    func updatePathControlWithSearch(text: String?) {
        guard let text = text else {
            pathControl.URL = NSURL(string: "southlake://localhost/library")
            updatePathControlAppearance()
            return
        }
        
        // The url should be of the format southlake://localhost/library/?search=text
        // But a path control doesn't know how to work with that.
        
        let encodedText = text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLQueryAllowedCharacterSet())
        let encodedPath = String(format: NSLocalizedString("Searching for \"%@\"", comment: ""), text).stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet())
        
        guard let queryValue = encodedText, let queryPath = encodedPath else {
            print("unable to encode search string")
            return
        }
        
        let query = String(format: "search=%@", queryValue)
        
        if let queryURL = NSURL(string: "southlake://localhost/library/?\(query)"),
           let pathURL = NSURL(string: "southlake://localhost/library/\(queryPath)") {
        
            pathControl.URL = pathURL
            updatePathControlAppearance()
            
            if let cell = pathControl.pathComponentCells()[safe: 1] {
                cell.URL = queryURL
            }
            
        } else {
            print("unable to create url for search text \(text)")
        }
    }
    
    func updatePathControlAppearance() {
        // First cell's string value is a capitalized, localized transformation of "tags"
        // First cell is black, remaining are blue
        
        let cells = pathControl.pathComponentCells()
        guard cells.count > 0 else {
            return
        }
        
        cells.first?.stringValue = cells.first!.stringValue.capitalizedString
        cells.first?.textColor = NSColor(white: 0.1, alpha: 1.0)
        
        for cell in cells[1..<cells.count] {
            cell.textColor = NSColor.keyboardFocusIndicatorColor()
        }
    }

}

