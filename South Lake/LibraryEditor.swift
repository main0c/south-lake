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
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"] }
    static var storyboard: String { return "LibraryEditor" }
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    dynamic var file: DataSource? {
        willSet {
        
        }
        didSet {
            loadLibrary()
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    // MARK: - Custom Properties
    
    dynamic var content: [DataSource] = [] {
        didSet {
            print(content)
        }
    }
    
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
        
        (view as! CustomizableView).backgroundColor = NSColor(white: 0.94, alpha: 1.0)
        
        collectionView.itemPrototype = storyboard!.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
        
        arrayController.sortDescriptors = [NSSortDescriptor(key: "created_at", ascending: false, selector: Selector("compare:"))]
        
        loadLibrary()
    }
    
    deinit {
        liveQuery.removeObserver(self, forKeyPath: "rows")
        liveQuery.stop()
    }
    
    func loadLibrary() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        let query = databaseManager.fileQuery

        liveQuery = query.asLiveQuery()
        liveQuery.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        liveQuery.start()
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if object as? NSObject == liveQuery {
            print("files changed: \(liveQuery.rows)")
            displayRows(liveQuery.rows)
        }
    }
    
    func displayRows(results: CBLQueryEnumerator?) {
        guard let results = results else {
            return
        }
        
        var files: [File] = []
            
        while let row = results.nextRow() {
            if let document = row.document {
                let file = CBLModel(forDocument: document) as! File
                files.append(file)
            }
        }
        
        content = files
    }
    
    // MARK: - User Actions
    
    @IBAction func filterByTitle(sender: AnyObject?) {
        guard let sender = sender as? NSSearchField else {
            return
        }
        
        let text = sender.stringValue
        
        if text == "" {
            arrayController.filterPredicate = nil
        } else {
            let predicate = NSPredicate(format: "title contains[cd] %@", text)
            arrayController.filterPredicate = predicate
        }
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
            descriptors = [NSSortDescriptor(key: "title",
                ascending: key != "title",
                selector: Selector("caseInsensitiveCompare:"))]
            break
        case 1002: // by date created
            descriptors = [NSSortDescriptor(key: "created_at",
                ascending: !(key != "created_at"),
                selector: Selector("compare:"))]
            break
        case 1003: // by date updated
            descriptors = [NSSortDescriptor(key: "updated_at",
                ascending: !(key != "updated_at"),
                selector: Selector("compare:"))]
            break
        default:
            break
        }
        
        arrayController.sortDescriptors = descriptors
    }
    
}

