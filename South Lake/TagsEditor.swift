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
            loadData()
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
    
    var liveQuery: CBLLiveQuery! {
        willSet {
            if let query = liveQuery {
                query.removeObserver(self, forKeyPath: "rows")
            }
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        (view as! CustomizableView).backgroundColor = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
        
        collectionView.itemPrototype = storyboard!.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
        
        sortDescriptors = [NSSortDescriptor(key: "tag", ascending: true, selector: Selector("caseInsensitiveCompare:"))]
        
        loadData()
    }
    
    deinit {
        liveQuery.removeObserver(self, forKeyPath: "rows")
        liveQuery.stop()
    }
    
    // MARK: - Tags Data
    
    func loadData() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        let query = databaseManager.tagsQuery
        query.groupLevel = 1
        
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
        
        var tags: [[String:AnyObject]] = []
        
        while let row = results.nextRow() {
            let count = row.value as! Int
            let tag = row.key as! String
            
            tags.append([
                "tag": tag,
                "count": count
            ])
        }
        
        content = tags
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
}
