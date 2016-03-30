//
//  TagsEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

private enum SortBy: Int {
    case Tag   = 1001
    case Count = 1002
}

class TagsEditor: NSViewController, DataSourceViewController {
    static var storyboard: String = "TagsEditor"
    static var filetypes: [String] = [
        "southlake.notebook.tags",
        "southlake/x-notebook-tags",
        "southlake-notebook-tags"
    ]
    
    @IBOutlet var libraryArrayController: NSArrayController!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var containerView: NSView!
    @IBOutlet var viewSelector: NSSegmentedControl!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var searchField: NSSearchField!
    
    // MARK: - Databasable
    
    var databaseManager: DatabaseManager? {
        didSet {
            sceneController?.databaseManager = databaseManager
            bindLibrary()
            bindTags()
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            sceneController?.searchService = searchService
        }
    }
    
    // MARK: - File Editor
    
    var isFileEditor: Bool {
        return false
    }
    
    var delegate: SelectionDelegate?
    dynamic var selectedObjects: [DataSource]?
    
    dynamic var source: DataSource?
    var layout: Layout = .None
    var scene: Scene = .None
    
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        return nil
    }
    
    // MARK: - Custom Propeties
    
    dynamic var sortDescriptors: [NSSortDescriptor]?
    dynamic var filterPredicate: NSPredicate?
    dynamic var content: [[String:AnyObject]]?
    
    dynamic var libraryContent: [DataSource] = []
    
    var sceneController: FileCollectionScene?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Appearance
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.DataSourceViewController
        pathControl.backgroundColor = UI.Color.Background.DataSourceViewController
        searchField.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    
        // TODO: save and restore tags sort
    
        sortDescriptors = initialSortDescriptors()
        
        // Path control
        
        // pathControl.cursor = NSCursor.pointingHandCursor()
        pathControl.URL = NSURL(string: "southlake://localhost/tags")
        updatePathControlAppearance()
        
        // Data
        
        loadScene("tagsCollectionScene")
        restoreView()
        
        bindLibrary()
        bindTags()
    }
    
    func willClose() {
        unloadScene()
        unbind("libraryContent")
        unbind("content")
    }
    
    func initialSortDescriptors() -> [NSSortDescriptor] {
        let keys = ["tag", "count"]
        
        if  let key = NSUserDefaults.standardUserDefaults().stringForKey("SLTagsSortKey") where keys.contains(key) {
            let ascending = NSUserDefaults.standardUserDefaults().boolForKey("SLTagsSortAscending")
            let selector = key == "tag" ? #selector(NSString.caseInsensitiveCompare(_:)) : #selector(NSNumber.compare(_:))
            return [NSSortDescriptor(key: key, ascending: ascending, selector: selector)]
        } else {
            return [NSSortDescriptor(key: "tag", ascending: true, selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        }
    }
    
    // MARK: - Tags and Library Data
    
    func bindTags() {
        guard let databaseManager = databaseManager else {
            return
        }
        guard unbound("content") else {
            return
        }
        
        bind("content", toObject: databaseManager, withKeyPath: "tags", options: [:])
    }
    
    func bindLibrary() {
        guard let databaseManager = databaseManager else {
            return
        }
        guard unbound("libraryContent") else {
            return
        }
        
        bind("libraryContent", toObject: databaseManager, withKeyPath: "files", options: [:])
    }
    
    // MARK: - User Actions
    
    @IBAction func filterByTitle(sender: AnyObject?) {
        guard let sender = sender as? NSSearchField else {
            return
        }
        
        let text = sender.stringValue
        filterPredicate = ( text == "" ) ? nil : NSPredicate(format: "tag contains[cd] %@", text)
    }
    
    @IBAction func sortByProperty(sender: AnyObject?) {
        guard let sender = sender as? NSPopUpButton else {
            log("sender mut be pop up button")
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
        case .Tag:
            descriptors = [NSSortDescriptor(key: "tag", ascending: (key == "tag" ? !asc : true), selector: #selector(NSString.caseInsensitiveCompare(_:)))]
        case .Count:
            descriptors = [NSSortDescriptor(key: "count", ascending: (key == "count" ? !asc : false), selector: #selector(NSNumber.compare(_:)))]
        }
        
        arrayController.sortDescriptors = descriptors
        
        // Save sort descriptors
        
        NSUserDefaults.standardUserDefaults().setObject(descriptors.first!.key!, forKey: "SLTagsSortKey")
        NSUserDefaults.standardUserDefaults().setBool(descriptors.first!.ascending, forKey: "SLTagsSortAscending")
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
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "url": url
        ])
    }
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        let sortBy = #selector(LibraryEditor.sortByProperty(_:))
        let action = menuItem.action
        let tag = menuItem.tag
        
        switch (action, tag) {
        case (sortBy, SortBy.Tag.rawValue):
            menuItem.state = sortDescriptors?.first?.key == "tag" ? NSOnState : NSOffState
            return true
        case (sortBy, SortBy.Count.rawValue):
            menuItem.state = sortDescriptors?.first?.key == "count" ? NSOnState : NSOffState
            return true
        case _:
            return false
        }
    }
    
    // MARK: - View
    
    func restoreView() {
        return ;
        // might guard against the scene
        let viewId = NSUserDefaults.standardUserDefaults().integerForKey("SLTagsView")
        viewSelector.selectSegmentWithTag(viewId)
        loadView(viewId)
    }
    
    func loadView(tag: Int) {
        switch tag {
        case 0: // icon collection
            useIconView()
            break
        case 1: // listing collection
            useListView()
            break
        case _:
            break
        }
    }
    
    func useIconView() {
        if let sceneController = sceneController as? TagsCollectionViewController {
            sceneController.useIconView()
        }
    }
    
    func useListView() {
        if let sceneController = sceneController as? TagsCollectionViewController {
            sceneController.useListView()
        }
    }
    
    // MARK: - Scene
    
    func loadScene(identifier: String) {
        sceneController = storyboard!.instantiateControllerWithIdentifier(identifier) as? FileCollectionScene
        guard var sceneController = sceneController else {
            log("unable to load scene with identifier \(identifier)")
            return
        }
        
        // Save the scene
        
        // NSUserDefaults.standardUserDefaults().setObject(identifier, forKey: "")
        
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
        // Check here if we're the right scene
        
        if identifier == "tagsCollectionScene" {
            sceneController.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
        } else {
            sceneController.arrayController.bind("contentArray", toObject: libraryArrayController, withKeyPath: "arrangedObjects", options: [:])
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
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
        pathControl.URL = url
        updatePathControlAppearance()
        
        // If the url contains a tag, load only those entries for the tag
        // Otherwise just show all tags
        
        if  let encodedTag = url.pathComponents?[safe: 2],
            let tag = encodedTag.stringByRemovingPercentEncoding {
            libraryArrayController.filterPredicate = NSPredicate(format: "%@ in tags", tag)
            loadScene("FileCardView")
        } else {
            loadScene("tagsCollectionScene")
            restoreView()
        }
    }
    
    // MARK: - Utilities
    
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

// MARK: - Search Field Delegate

// Doesn't quite work the same way as it does with a token field

//extension TagsEditor: NSControlTextEditingDelegate {
//    var completingTag: Bool = false // field autocompletion
//    
//    override func controlTextDidChange(notification: NSNotification) {
//        guard let userInfo = notification.userInfo,
//              let textView = userInfo["NSFieldEditor"] as? NSTextView
//              where !completingTag else {
//              return
//        }
//        
//        completingTag = true
//        textView.complete(nil)
//        completingTag = false
//    }
//    
//    func control(control: NSControl, textView: NSTextView, completions words: [String], forPartialWordRange charRange: NSRange, indexOfSelectedItem index: UnsafeMutablePointer<Int>) -> [String] {
//        
//        guard let text = textView.string,
//              let range = text.rangeFromNSRange(charRange) else {
//              return []
//        }
//        
//        let substring = text.substringWithRange(range)
//        let predicate = NSPredicate(format: "tag BEGINSWITH[cd] %@", substring)
//        
//        log(words)
//        
//        return content!
//            .filter { predicate.evaluateWithObject($0) }
//            .map { ($0["tag"] as! String) }
//    }
//}
