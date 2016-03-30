//
//  FolderEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/23/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  TODO: Definitely refactor FolderEditor and LibraryEditor

import Cocoa

private enum SortBy: Int {
    case Title   = 1001
    case Created = 1002
    case Updated = 1003
}

class FolderEditor: NSViewController, DataSourceViewController {
    static var storyboard: String = "FolderEditor"
    static var filetypes: [String] = [
        "southlake.folder",
        "southlake/x-folder",
        "southlake-folder",
        "southlake.smart-folder",
        "southlake/x-smart-folder",
        "southlake-smart-folder",
        "southlake/x-notebook-inbox",
        "southlake.notebook.inbox",
        "southlake-notebook-inbox"
    ]
    
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var noSearchResultsLabel: NSTextField!
    @IBOutlet var searchField: NSSearchField!
    
    // MARK: - File Editor
    
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
    
    var delegate: SelectionDelegate?
    
    // What I want is to not use bindings at all for selection, which cause misfires,
    // but collection view delegate selection callbacks have inexplicably stopped working
    
    private var ignoreChangeInSelection = false
    
    dynamic var selectedObjects: [DataSource]? {
        didSet {
            guard !ignoreChangeInSelection else {
                return
            }
            guard let delegate = delegate, let selection = selectedObjects else {
                return
            }
            
            delegate.object(self, didChangeSelection: selection)
        }
    }
    
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
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.DataSourceViewController
        pathControl.backgroundColor = UI.Color.Background.DataSourceViewController
        
        sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: #selector(NSNumber.compare(_:)))]
        
        // pathControl.cursor = NSCursor.pointingHandCursor()
        pathControl.URL = NSURL(string: "southlake://localhost/library")
        updatePathControlAppearance()
        
        searchField.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
        
        loadScene(scene)
        bindContent()
    }
    
    func willClose() {
        unloadScene()
        unbind("content")
    }

    // MARK: - Folder Data
    
    func bindContent() {
        guard viewLoaded else {
            return
        }
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
        guard let sender = sender as? NSPopUpButton else { // NSMenuItem
            return
        }
        guard let property = SortBy(rawValue: sender.selectedTag()) else {
            log("unkonwn property")
            return
        }
        
        // Selecting the same menu item reverses the sort
        
        var descriptors = arrayController.sortDescriptors
        let asc = descriptors[safe: 0]?.ascending ?? true
        let key = descriptors[safe: 0]?.key
        
        switch property {
        case .Title:
            descriptors = [NSSortDescriptor(key: "title", ascending: (key == "title" ? !asc : true), selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        case .Created:
            descriptors = [NSSortDescriptor(key: "created_at", ascending: (key == "created_at" ? !asc : false), selector: #selector(NSNumber.compare(_:)))]
        case .Updated:
            descriptors = [NSSortDescriptor(key: "updated_at", ascending: (key == "updated_at" ? !asc : false), selector: #selector(NSNumber.compare(_:)))]
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
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        let sortBy = #selector(LibraryEditor.sortByProperty(_:))
        let action = menuItem.action
        let tag = menuItem.tag
        
        switch (action, tag) {
        case (sortBy, SortBy.Title.rawValue):
            menuItem.state = sortDescriptors?.first?.key == "title" ? NSOnState : NSOffState
            return true
        case (sortBy, SortBy.Created.rawValue):
            menuItem.state = sortDescriptors?.first?.key == "created_at" ? NSOnState : NSOffState
            return true
        case (sortBy, SortBy.Updated.rawValue):
            menuItem.state = sortDescriptors?.first?.key == "updated_at" ? NSOnState : NSOffState
            return true
        case _:
            return false
        }
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
        sceneController!.delegate = self
        
        if let selection = selection {
            whileIgnoringChangeInSelection {
                self.sceneController!.arrayController.setSelectedObjects(selection)
            }
        }
    }
    
    func unloadScene() {
        guard let sceneController = sceneController else {
            return
        }
        
        whileIgnoringChangeInSelection {
            sceneController.arrayController.unbind("contentArray")
            sceneController.arrayController.content = []
            sceneController.view.removeFromSuperview()
            sceneController.willClose()
        }
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
    
    func whileIgnoringChangeInSelection(whileIgnoring: Void -> Void) {
        ignoreChangeInSelection = true
        whileIgnoring()
        ignoreChangeInSelection = false
    }
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
        NSBeep()
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

extension FolderEditor: SelectionDelegate {
    
    func object(object: AnyObject, didChangeSelection selection: [AnyObject]) {
        guard let selection = selection as? [DataSource] else {
            return
        }
        guard !ignoreChangeInSelection else {
            return
        }
        
        selectedObjects = selection
    }
}