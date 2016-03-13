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
    
    func documentWillSave(notification: NSNotification) {
    
    }
    
    func willClose() {
    
    }
    
    // MARK: - User Actions
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        NSBeep()
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject?) {
        NSBeep()
    }
    
    @IBAction func createNewFolder(sender: AnyObject?) {
        NSBeep()
    }
    
    @IBAction func makeFilesAndFoldersFirstResponder(sender: AnyObject?) {
        NSBeep()
    }
    
    @IBAction func makeEditorFirstResponder(sender: AnyObject?) {
        NSBeep()
    }
    
    @IBAction func makeFileInfoFirstResponder(sender: AnyObject?) {
        NSBeep()
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case Selector("createNewMarkdownDocument:"),
             Selector("createNewSmartFolder:"),
             Selector("createNewFolder:"),
             Selector("makeFilesAndFoldersFirstResponder:"),
             Selector("makeEditorFirstResponder:"),
             Selector("makeFileInfoFirstResponder:"):
             return false
        default:
             return false
        }
    }
    
    // MARK: -
    
    func performSearch(text: String?, results: BRSearchResults?) {
        print("perform search for: \(text)")
        
        guard let results = results where results.count() != 0 else {
            print("search service returned no results")
            textView.string = String.localizedStringWithFormat(NSLocalizedString("No results found for \"%@\"", comment: "No results message"),
                text)
            return
        }
        
        title = String.localizedStringWithFormat(NSLocalizedString("Find Results: \"%@\"",
                comment: "Title of find tab"),
                text)
        
        var presentation = ""
        
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
