//
//  FolderEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/23/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  TODO: Definitely refactor FolderEditor and LibraryEditor

import Cocoa

class FolderEditor: NSViewController, DataSourceViewController {

    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var sceneSelector: NSSegmentedControl!
    @IBOutlet var noSearchResultsLabel: NSTextField!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return [
        "southlake.folder", "southlake/x-folder", "southlake-folder",
        "southlake.smart-folder", "southlake/x-smart-folder", "southlake-smart-folder"
    ] }
    static var storyboard: String { return "LibraryEditor" }
    
    var databaseManager: DatabaseManager? {
        didSet {
            sceneController?.databaseManager = databaseManager
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
    
    var delegate: SelectionDelegate?
    dynamic var selectedObjects: [DataSource]?
    var layout: Layout = .None
    var scene: Scene = .None
    
    dynamic var source: DataSource? {
        willSet {
            if let _ = source {
                unbind("content")
            }
        }
        didSet {
            bindContent()
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

    var sceneController: FileCollectionScene?

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.DataSourceViewController
        pathControl.backgroundColor = UI.Color.Background.DataSourceViewController
        
        sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: #selector(NSNumber.compare(_:)))]
        
        // pathControl.cursor = NSCursor.pointingHandCursor()
        pathControl.URL = NSURL(string: "southlake://localhost/library")
        updatePathControlAppearance()
        
        // Restore view preference
        
        let sceneId = NSUserDefaults.standardUserDefaults().objectForKey("SLLibraryScene") as? String ?? "FileCardView"
        sceneSelector.selectSegmentWithTag(sceneId == "FileCardView" ? 0 : 1)
        
        loadScene(sceneId)
        bindContent()
    }
    
    func willClose() {
        unloadScene()
        unbind("content")
    }

    // MARK: - Library Data
    
    func bindContent() {
        guard let source = source else {
            return
        }
        guard unbound("content") else {
            return
        }
        
        bind("content", toObject: source, withKeyPath: "children", options: [:])
        
        // TODO: bind path control value somewhere
        
        updatePathControlWithTitle(source.title)
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
    
    @IBAction func changeLayout(sender: AnyObject?) {
        guard let sender = sender as? NSSegmentedControl,
              let cell = sender.cell as? NSSegmentedCell else {
              return
        }
        
        let segment = sender.selectedSegment
        let tag = cell.tagForSegment(segment)
        
        switch tag {
        case 0: // icon collection
            unloadScene()
            NSUserDefaults.standardUserDefaults().setObject("FileCardView", forKey: "SLLibraryScene")
            loadScene("FileCardView")
        case 1: // table view
            unloadScene()
            NSUserDefaults.standardUserDefaults().setObject("FileTableView", forKey: "SLLibraryScene")
            loadScene("FileTableView")
        case _:
            break
        }
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
    
    func loadScene(identifier: String) {
        sceneController = NSStoryboard(name: identifier, bundle: nil).instantiateInitialController() as? FileCollectionScene
        guard var sceneController = sceneController else {
            log("unable to load scene")
            return
        }
        
        // Databasable
        
        sceneController.databaseManager = databaseManager
        sceneController.searchService = searchService
        
        // Set up frame and view constraints
        
        sceneController.view.translatesAutoresizingMaskIntoConstraints = false
        sceneController.view.frame = containerView.bounds
        containerView.addSubview(sceneController.view)
        
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": sceneController.view])
        )
        containerView.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": sceneController.view])
        )
        
        // Bind the array controller to ours
        // Predicates and sorting are applied before it even sees the data
        
        sceneController.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
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
    
    func updatePathControlWithTitle(text: String?) {
        guard let text = text else {
            pathControl.URL = nil
            updatePathControlAppearance()
            return
        }
        
        // The url should be of the format southlake://localhost/folder-name
        // But a path control doesn't know how to work with that.
        
        // TODO: this is actually not enough information to recover the folder
        // Two folders may have the same name. Need to encode the folder id
        
        guard let encodedText = text.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
            log("unable to encode title")
            return
        }
        
        if let pathURL = NSURL(string: "southlake://localhost/\(encodedText)") {
            pathControl.URL = pathURL
            updatePathControlAppearance()
        } else {
            log("unable to create url for title \(text)")
        }
    }
    
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
