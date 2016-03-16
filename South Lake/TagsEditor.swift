//
//  TagsEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TagsEditor: NSViewController, FileEditor {
    @IBOutlet var libraryArrayController: NSArrayController!
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var searchLabel: NSTextField!
    @IBOutlet var containerView: NSView!

    static var filetypes: [String] { return ["southlake.notebook.tags", "southlake/x-notebook-tags", "southlake-notebook-tags"] }
    static var storyboard: String { return "TagsEditor" }
    
    // MARK: - Databasable
    
    var databaseManager: DatabaseManager! {
        didSet {
            scene?.databaseManager = databaseManager
            bindLibrary()
            bindTags()
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
            scene?.searchService = searchService
        }
    }
    
    // MARK: - File Editor
    
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
    
    // MARK: - Custom Propeties
    
    dynamic var sortDescriptors: [NSSortDescriptor]?
    dynamic var filterPredicate: NSPredicate?
    dynamic var content: [[String:AnyObject]]?
    
    dynamic var libraryContent: [DataSource] = []
    
    var scene: LibraryScene?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        searchLabel.hidden = true
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
    
        sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        loadScene("tagsCollectionScene")
        bindLibrary()
        bindTags()
    }
    
    deinit {
        unbind("libraryContent")
        unbind("content")
    }
    
    // MARK: - Tags Data
    
    func bindTags() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        bind("content", toObject: databaseManager, withKeyPath: "tags", options: [:])
    }
    
    // MARK: - Library Data
    
    func bindLibrary() {
        guard (databaseManager as DatabaseManager?) != nil else {
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
        guard let sender = sender as? NSMenuItem else {
            return
        }
        
        var descriptors = arrayController.sortDescriptors
        let key = descriptors.count != 0 ? descriptors[0].key : nil
        
        // Selecting the same item twice reverses the sort
        // But by default show most recent files first
        
        // TODO: reverse sort on same key
        
        switch sender.tag {
        case 1001: // by tag
            descriptors = [NSSortDescriptor(key: "tag", ascending: key != "title", selector: Selector("caseInsensitiveCompare:"))]
        case 1002: // by count
            descriptors = [NSSortDescriptor(key: "count", ascending: !(key != "count"), selector: Selector("compare:"))]
        default:
            break
        }
        
        arrayController.sortDescriptors = descriptors
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
        // Check here if we're the right scene
        
        if identifier == "tagsCollectionScene" {
            scene.arrayController.bind("contentArray", toObject: arrayController, withKeyPath: "arrangedObjects", options: [:])
        } else {
            scene.arrayController.bind("contentArray", toObject: libraryArrayController, withKeyPath: "arrangedObjects", options: [:])
        }
    }
    
    func unloadScene() {
        guard let scene = scene else {
            return
        }
        
        scene.arrayController.unbind("contentArray")
        scene.view.removeFromSuperview()
    }
    
    // MARK: -
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard let object = arrayController.selectedObjects[safe: 0] as? [String:AnyObject],
              let tag = object["tag"] as? String,
              let encodedTag = tag.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
            print("no selected object")
            return
        }
        
        guard let url = NSURL(string: "southlake://localhost/tags/\(encodedTag)") else {
            print("unable to construct url for object with id \(encodedTag)")
            return
        }
        
        // TODO: Track history
        
        print(url)
        openURL(url)
    }
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
        guard let encodedTag = url.pathComponents?[safe: 2],
              let tag = encodedTag.stringByRemovingPercentEncoding else {
            searchLabel.hidden = true
            return
        }
        
        searchLabel.stringValue = tag
        searchLabel.hidden = ( tag == "" )
        
        // Filter on the tag, load a scene and morph the toolbar
        
        libraryArrayController.filterPredicate = NSPredicate(format: "%@ in tags", tag)
        loadScene("libraryCollectionScene")
    }
    
    func willClose() {
    
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
//        print(words)
//        
//        return content!
//            .filter { predicate.evaluateWithObject($0) }
//            .map { ($0["tag"] as! String) }
//    }
//}
