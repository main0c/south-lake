//
//  TagEditor.swift
//  South Lake
//
//  Created by Philip Dow on 4/4/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

private enum SortBy: Int {
    case Title   = 1001
    case Created = 1002
    case Updated = 1003
}

class TagEditor: NSViewController, SelectableSourceViewer {
    static var storyboard: String = "TagEditor"
    static var filetypes: [String] = [
        "southlake/x-tag",
        "southlake-tag",
        "southlake.tag"
    ]
    
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var noSearchResultsLabel: NSTextField!
    @IBOutlet var searchField: NSSearchField!
    
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
    
    dynamic var source: DataSource? {
        didSet {
            loadFile(source)
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
            // For now file content for a tag only selects on double click and is always displayed in a large view
            sceneController!.selectsOnDoubleClick = true
            sceneController!.maximize()
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        return nil
    }
    
    var selectionDelegate: SelectionDelegate?
    private var ignoreChangeInSelection = false
    
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
        
        // Custom appearance
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.SourceViewer
        pathControl.backgroundColor = UI.Color.Background.SourceViewer
        searchField.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
        
        // Restore sort descriptors or provide defaults
        
        sortDescriptors = initialSortDescriptors()
        
        // Path control
        
        // pathControl.cursor = NSCursor.pointingHandCursor()
        pathControl.URL = NSURL(string: "southlake://localhost/tag")
        updatePathControlAppearance()
        
        // Data
        
        loadScene(scene)
        bindContent()
        loadFile(source)
    }
    
    func willClose() {
        unloadScene()
        unbind("content")
    }

    func initialSortDescriptors() -> [NSSortDescriptor] {
        let keys = ["title", "created_at", "updated_at"]
        
        if  let key = NSUserDefaults.standardUserDefaults().stringForKey("SLFolderSortKey") where keys.contains(key) {
            let ascending = NSUserDefaults.standardUserDefaults().boolForKey("SLFolderSortAscending")
            let selector = key == "title" ? #selector(NSString.caseInsensitiveCompare(_:)) : #selector(NSNumber.compare(_:))
            return [NSSortDescriptor(key: key, ascending: ascending, selector: selector)]
        } else {
            return [NSSortDescriptor(key: "created_at", ascending: false, selector: #selector(NSNumber.compare(_:)))]
        }
    }

    // MARK: - Library and Source Data
    
    func bindContent() {
        guard viewLoaded else {
            return
        }
        guard let databaseManager = databaseManager else {
            return
        }
        guard unbound("content") else {
            return
        }
        
        bind("content", toObject: databaseManager, withKeyPath: "files", options: [:])
    }
    
    func loadFile(file: DataSource?) {
        guard let file = file as? Tag else {
            return
        }
        guard let source = source else {
            return
        }
        guard viewLoaded else {
            return
        }
       
        // Filter on the tag's value
        
        titlePredicate = NSPredicate(format: "any tags like[cd] %@", file.title)
        
        // Update the path control
        
        updatePathControlWithTitle(source.title)
    }

    
    // MARK: - User Actions
    
    @IBAction func filterByTitle(sender: AnyObject?) {
        guard let sender = sender as? NSSearchField else {
            return
        }
        guard let source = source else {
            return
        }
        
        let text = sender.stringValue
        titlePredicate = ( text == "" )
            ? NSPredicate(format: "any tags like[cd] %@", source.title)
            : NSPredicate(format: "title contains[cd] %@ && any tags like[cd] %@", text, source.title)
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
        
        // Save sort descriptors
        
        NSUserDefaults.standardUserDefaults().setObject(descriptors.first!.key!, forKey: "SLFolderSortKey")
        NSUserDefaults.standardUserDefaults().setBool(descriptors.first!.ascending, forKey: "SLFolderSortAscending")
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
        
        // Preserve the selection
        
        let selection = sceneController?.selectedObjects
        
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
        // For now file content for a tag only selects on double click and is always displayed in a large view
        
        sceneController!.selectsOnDoubleClick = true
        sceneController!.maximize()
        
        // Set up connections
        
        sceneController!.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
        sceneController!.selectionDelegate = self
        
        // Restore the selection
        
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

extension TagEditor: SelectionDelegate {
    
    func object(object: AnyObject, didChangeSelection selection: [AnyObject]) {
        guard let selectionDelegate = selectionDelegate else {
            return
        }
        guard let selection = selection as? [DataSource] else {
            return
        }
        guard !ignoreChangeInSelection else {
            return
        }
        
        selectionDelegate.object(self, didChangeSelection: selection)
    }
}
