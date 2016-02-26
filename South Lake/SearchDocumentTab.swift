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
    @IBOutlet var textView: NSTextView!
    
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
        
        textView.textColor = NSColor(calibratedWhite: 0.95, alpha: 1.0)
        textView.font = NSFont.systemFontOfSize(13)
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
        var presentation = ""
        
        guard let results = searchService.search(text) else {
            print("search service returned nil for results")
            return
        }
        
        guard results.count() != 0 else {
            textView.string = String.localizedStringWithFormat(NSLocalizedString("No results found for \"%@\"",
                comment: "No results message"),
                searchPhrase)
            return
        }
        
        results.iterateWithBlock { (index: UInt, result: BRSearchResult!, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
            guard let _ = result.dictionaryRepresentation(),
                  let documentTitle = result.valueForField("t") as? String,
                  let _ = result.valueForField("id") as? String,
                  let documentText = result.valueForField("v") as? String else {
                  return
            }
            
            // print("found result: \(info)")
            presentation.appendContentsOf(documentTitle)
            presentation.appendContentsOf(" : ")
            // presentation.appendContentsOf(documentID)
            presentation.appendContentsOf("\n")
            
            // NSAttibutedString.nextWordFromIndex,forward
            
            documentText.enumerateSubstringsInRange(Range<String.Index>(start: documentText.startIndex, end: documentText.endIndex), options: .ByParagraphs, { (substring, substringRange, enclosingRange, stop) -> () in
                guard let substring = substring else {
                    return
                }
                
                guard let _ = substring.rangeOfString(text, options: .CaseInsensitiveSearch, range: nil, locale: nil) else {
                    return
                }
                
                presentation.appendContentsOf("\n")
                presentation.appendContentsOf("\t")
                presentation.appendContentsOf(substring)
                presentation.appendContentsOf("\n")
            })
            
//            presentation.appendContentsOf("\t...some of the text for context clickable...")
//            presentation.appendContentsOf("\n")
//            presentation.appendContentsOf("\t...more context clickable...")
            
            presentation.appendContentsOf("\n\n")
        }
        
        textView.string = presentation
    }
}
