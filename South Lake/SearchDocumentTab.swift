//
//  SearchDocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/25/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Architecture:
//  Is there a standard property for passing data that all tabs follow?
//  Here I want "searchterm" but maybe there's something more generic

import Cocoa

class SearchDocumentTab: NSViewController, DocumentTab {
    dynamic var selectedObjects: [DataSource] = []
    dynamic var icon: NSImage?
    
    var databaseManager: DatabaseManager! {
        didSet {
        
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
        
        }
    }
    
    var searchPhrase: String = "" {
        didSet {
            performSearch(searchPhrase)
            title = String.localizedStringWithFormat(NSLocalizedString("Find Results: \"%@\"",
                comment: "Title of find tab"),
                searchPhrase)
        }
    }

    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        title = NSLocalizedString("Find Results", comment: "Title of find tab")
    }
    
    // MARK: -
    
    func state() -> Dictionary<String,AnyObject> {
        return ["Title": (title ?? "")]
    }
    
    func restoreState(state: Dictionary<String,AnyObject>) {
    
    }
    
    func createNewMarkdownDocument(sender: AnyObject?) {
    
    }
    
    func documentWillSave(notification: NSNotification) {
    
    }
    
    func willClose() {
    
    }
    
    // MARK: -
    
    func performSearch(text: String) {
        print("perform search for: \(text)")
        
        let results = searchService.search(text)
        print("\(results)")
        
        results.iterateWithBlock { (index: UInt, result: BRSearchResult!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            let info = result.dictionaryRepresentation()
            print("found result: \(info)")
        }
    }
}
