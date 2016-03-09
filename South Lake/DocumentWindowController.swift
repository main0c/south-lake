//
//  DocumentWindowController.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Primary document interface. Should route first responder calls when view controllers
//  aren't in the responder chain, routes or handles menu and toolbar state.

import Cocoa

class DocumentWindowController: NSWindowController, Databasable {
    var tabController: DocumentTabController! {
        return self.window?.contentViewController as! DocumentTabController
    }
    
    var databaseManager: DatabaseManager! {
        didSet {
            tabController.databaseManager = databaseManager
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
            tabController.searchService = searchService
        }
    }
    
    // MARK: - Initialization
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    // MARK: - Tab Actions
    
    /// Close the currently selected tab if more than one tab is visible.
    /// Otherwise close the window.
    
    @IBAction func performTabbedClose(sender: AnyObject?) {
        if tabController.count == 1 {
            closeWindow(sender)
        } else {
            closeTab(sender)
        }
    }
    
    @IBAction func closeWindow(sender: AnyObject?) {
        guard let window = self.window else {
            return
        }
        window.performClose(sender)
    }
    
    @IBAction func closeTab(sender: AnyObject?) {
        tabController.performClose(sender)
    }

    @IBAction func createNewTab(sender: AnyObject?) {
        tabController.createNewTab(sender)
    }
    
    @IBAction func selectNextTab(sender: AnyObject?) {
        tabController.selectNextTab(sender)
    }
    
    @IBAction func selectPreviousTab(sender: AnyObject?) {
        tabController.selectPreviousTab(sender)
    }
    
    // MARK: - Routable User Actions
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        tabController.createNewMarkdownDocument(sender)
    }
    
    @IBAction func createNewFolder(sender: AnyObject?) {
        tabController.createNewFolder(sender)
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject?) {
        tabController.createNewSmartFolder(sender)
    }
    
    @IBAction func makeFilesAndFoldersFirstResponder(sender: AnyObject?) {
        tabController.makeFilesAndFoldersFirstResponder(sender)
    }
    
    @IBAction func makeEditorFirstResponder(sender: AnyObject?) {
        tabController.makeEditorFirstResponder(sender)
    }
    
    @IBAction func makeFileInfoFirstResponder(sender: AnyObject?) {
        tabController.makeFileInfoFirstResponder(sender)
    }
    
    // MARK: - Search Actions
    
    @IBAction func findInNotebook(sender: AnyObject?) {
        guard let item = window?.toolbar?.itemWithIdentifier("search"),
              let field = item.view as? NSSearchField else {
            return
        }
        
        window?.makeFirstResponder(field)
    }
    
    /// Replace the current search tab with a new search or create a new search tab and search.
    /// Called when the search field executes its action.
    
    @IBAction func executeFindInNotebook(sender: AnyObject?) {
        
        guard let sender = sender as? NSSearchField
              where sender.stringValue.characters.count > 0 else {
              return
        }
        
        let text = sender.stringValue
        var searchTab: SearchDocumentTab
        
        if tabController.selectedTab is SearchDocumentTab {
            searchTab = tabController.selectedTab as! SearchDocumentTab
        } else {
            do {
                guard let item = try tabController.createNewSearchTab(),
                      let tab = item.vc as? SearchDocumentTab else {
                    print("don't have search tab")
                    return
                }
                searchTab = tab
            } catch {
                print(error)
                return
            }
        }
        
        searchTab.performSearch(text, results: searchService.search(text))
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case Selector("performTabbedClose:"):
             menuItem.title = closeMenuTitle()
             return true
        case Selector("createNewMarkdownDocument:"),
             Selector("createNewSmartFolder:"),
             Selector("createNewFolder:"),
             Selector("makeFilesAndFoldersFirstResponder:"),
             Selector("makeEditorFirstResponder:"),
             Selector("makeFileInfoFirstResponder:"):
             return tabController.validateMenuItem(menuItem)
        case Selector("closeTab:"),
             Selector("createNewTab:"),
             Selector("selectNextTab:"),
             Selector("selectPreviousTab:"):
            return tabController.validateMenuItem(menuItem)
        case Selector("findInNotebook:"),
             Selector("closeWindow:"):
             return true
        default:
             return false
        }
    }
    
    func closeMenuTitle() -> String {
        return tabController.count == 1
            ? NSLocalizedString("Close", comment: "Close window")
            : NSLocalizedString("Close Tab", comment: "Close tab")
    }
    
    // MARK: - Document State
    
    /// Returns the state of the window, which includes each tab returning its own state,
    /// e.g. tab class, layout, selection, etc ...
    
    func state() -> Dictionary<String,AnyObject> {
        let tabState = tabController.state()
        return ["TabController": tabState]
    }
    
    /// Restore the window state including the state of each tab
    
    func restoreState(state: Dictionary<String,AnyObject>) {
        if let tabState = state["TabController"] as? Dictionary<String,AnyObject> {
            tabController.restoreState(tabState)
        }
    }
    
}
