//
//  TagsEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TagsEditor: NSViewController, FileEditor {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!

    static var filetypes: [String] { return ["southlake.notebook.tags", "southlake/x-notebook-tags", "southlake-notebook-tags"] }
    static var storyboard: String { return "TagsEditor" }
    
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
        willSet {
        
        }
        didSet {
            bindTags()
        }
    }
    
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
    
    var completingTag: Bool = false
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        collectionView.itemPrototype = storyboard!.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
        
        sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        bindTags()
    }
    
    deinit {
        unbind("content")
    }
    
    // MARK: - Tags Data
    
    func bindTags() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        bind("content", toObject: databaseManager, withKeyPath: "tags", options: [:])
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
        
        switch sender.tag {
        case 1001: // by tag
            descriptors = [NSSortDescriptor(key: "tag", ascending: key != "title", selector: Selector("caseInsensitiveCompare:"))]
        case 1002: // by count
            descriptors = [NSSortDescriptor(key: "count", ascending: !(key != "created_at"), selector: Selector("compare:"))]
        default:
            break
        }
        
        arrayController.sortDescriptors = descriptors
    }
    
    // MARK: - 
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
}

// MARK: - Search Field Delegate

// Doesn't quite work the same way as it does with a token field

//extension TagsEditor: NSControlTextEditingDelegate {
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
