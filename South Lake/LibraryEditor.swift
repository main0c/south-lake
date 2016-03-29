//
//  LibraryEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

/// TODO: move to LibraryEditor or FolderEditor?

enum FileView: String {
    case Card = "FileCardView"
    case Table = "FileTableView"
    case List = "FileListView"
}

/// Loads the contents of the library and supports filtering and sorting those 
/// contents. Switches between the card, table and list views for those contents.
/// Maintains a list of selected objects, which an interested party can bind to.

class LibraryEditor: NSViewController, SourceViewer {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var noSearchResultsLabel: NSTextField!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"] }
    static var storyboard: String { return "LibraryEditor" }
    
    var databaseManager: DatabaseManager? {
        didSet {
            sceneController?.databaseManager = databaseManager
            bindContent()
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            sceneController?.searchService = searchService
        }
    }
    
    var isFileEditor: Bool {
        return false
    }
    
    dynamic var source: DataSource?
    
    var scene: Scene = .None {
        didSet {
            if scene != oldValue {
                loadScene(scene)
            }
        }
    }
    
    var layout: Layout = .None {
        didSet {
            if layout == .Compact {
                sceneController?.minimize()
            } else {
                sceneController?.maximize()
            }
            if layout == .Expanded {
                sceneController?.selectsOnDoubleClick = true
            } else {
                sceneController?.selectsOnDoubleClick = false
            }
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        return nil
    }
    
    dynamic var selectedObjects: [DataSource]?
    
    // MARK: - Custom Properties
    
    dynamic var sortDescriptors: [NSSortDescriptor]?
    dynamic var filterPredicate: NSPredicate?
    dynamic var content: [DataSource]?
    
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

    var sceneController: FileCollectionScene?

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.SourceViewer
        pathControl.backgroundColor = UI.Color.Background.SourceViewer
        
        sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: #selector(NSNumber.compare(_:)))]
        
        // pathControl.cursor = NSCursor.pointingHandCursor()
        pathControl.URL = NSURL(string: "southlake://localhost/library")
        updatePathControlAppearance()
        
        loadScene(scene)
        bindContent()
    }
    
    func willClose() {
        unloadScene()
        unbind("content")
        unbind("selectedObjects")
    }

    // MARK: - Library Data
    
    func bindContent() {
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
            descriptors = [NSSortDescriptor(key: "title", ascending: (key == "title" ? !asc : true), selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        case 1002: // by date created
            descriptors = [NSSortDescriptor(key: "created_at", ascending: (key == "created_at" ? !asc : false), selector: #selector(NSNumber.compare(_:)))]
        case 1003: // by date updated
            descriptors = [NSSortDescriptor(key: "updated_at", ascending: (key == "updated_at" ? !asc : false), selector: #selector(NSNumber.compare(_:)))]
        default:
            break
        }
        
        arrayController.sortDescriptors = descriptors
    }
    
    @IBAction func gotoPath(sender: AnyObject?) {
//        guard let databaseManager = databaseManager else {
//            return
//        }
//        guard let sender = sender as? NSPathControl else {
//            return
//        }
//        guard let url = sender.clickedPathComponentCell()?.URL else {
//            return
//        }
//        
//        // TODO: finish
//        
//        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
//            "dbm": databaseManager,
//            "url": url
//        ])
    }
    
    // MARK: - Scene
   
    func loadScene(scene: Scene) {
        guard scene != .None else {
            return
        }
        guard viewLoaded else {
            return
        }
        guard let storyboard = storyboardForScene(scene) else {
            log("no storyboard for scene \(scene)")
            return
        }
        guard let sc = storyboard.instantiateInitialController() as? FileCollectionScene else {
            log("no initial view controller for scene \(scene)")
            return
        }
        
        // Preserve the selected objects
        
        let selection = selectedObjects
        
        // Prepare the scene
        
        unloadScene()
        sceneController = sc
        
        // Databasable
        
        sceneController!.databaseManager = databaseManager
        sceneController!.searchService = searchService
        
        // Place it into the container
        
        sceneController!.view.translatesAutoresizingMaskIntoConstraints = false
        sceneController!.view.frame = containerView.bounds
        containerView.addSubview(sceneController!.view)
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": sceneController!.view])
        )
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": sceneController!.view])
        )
        
        // Prepare interface
        
        if layout == .Compact {
            sceneController!.minimize()
        } else {
            sceneController!.maximize()
        }
        
        if layout == .Expanded {
            sceneController!.selectsOnDoubleClick = true
        } else {
            sceneController!.selectsOnDoubleClick = false
        }
        
        // Set up connections
        
        sceneController!.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
        bind("selectedObjects", toObject: sceneController as! AnyObject, withKeyPath: "selectedObjects", options: [:])
        
        if let selection = selection {
            sceneController!.arrayController.setSelectedObjects(selection)
        }
    }
    
    func unloadScene() {
        guard let sceneController = sceneController else {
            return
        }
        
        sceneController.arrayController.unbind("contentArray")
        sceneController.arrayController.content = []
        sceneController.view.removeFromSuperview()
        sceneController.willClose()
    }
    
    func storyboardForScene(scene: Scene) -> NSStoryboard? {
        switch scene {
        case .Table:
            return NSStoryboard(name: "FileTableView", bundle: nil)
        case .Card:
            return NSStoryboard(name: "FileCardView", bundle: nil)
        case .List:
            return NSStoryboard(name: "FileListView", bundle: nil)
        case .None:
            return nil
        }
    }
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
        noSearchResultsLabel.hidden = true
        updatePathControlWithSearch(text)
        
        guard let _ = text else {
            searchPredicate = nil
            return
        }
        guard let results = results where results.count() != 0 else {
            searchPredicate = NSPredicate(value: false)
            noSearchResultsLabel.hidden = false
            return
        }
        
        // Map results to an array of document ids
        
        var ids: [String] = []
        
        results.iterateWithBlock { (index: UInt, result: BRSearchResult!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            // guard let _ = result.dictionaryRepresentation()
            // let _ = result.valueForField("t") as? String,
            // let _ = result.valueForField("v") as? String
            
            guard var id = result.valueForField("id") as? String else {
                  return
            }
            
            if id[id.startIndex] == "?" { // kBRSimpleIndexableSearchObjectType
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
    
    // MARK: - Path Control
    
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
            log("unable to encode search string")
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
            log("unable to create url for search text \(text)")
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

