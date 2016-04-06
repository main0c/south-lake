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
    
    var databaseManager: DatabaseManager? {
        didSet {
            tabController.databaseManager = databaseManager
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            tabController.searchService = searchService
        }
    }
    
    // MARK: - Initialization
    
    override func windowDidLoad() {
        super.windowDidLoad()

        // Transparent Window
        
        // window!.styleMask = window!.styleMask | NSFullSizeContentViewWindowMask
        // window!.titlebarAppearsTransparent = true
        
        // let view = window!.contentView!
        // let constraint = NSLayoutConstraint(item: view, attribute: .Top, relatedBy: .Equal, toItem: window!.contentLayoutGuide, attribute: .Top, multiplier: 1, constant: 0)
        
        // constraint.active = true
        
        NSNotificationCenter.defaultCenter().addObserver(self,
            selector: #selector(DocumentWindowController.handleOpenURLNotification(_:)),
            name: OpenURLNotification,
            object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
    
    @IBAction func changeLayout(sender: AnyObject?) {
        tabController.changeLayout(sender)
    }
    
    @IBAction func toggleDocumentHeader(sender: AnyObject?) {
        tabController.toggleDocumentHeader(sender)
    }
    
    // MARK: -
    
    // TODO: handleOpenURLNotification may not need the source. We can just get it from the id anyway
    
    func handleOpenURLNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let dbm = userInfo["dbm"] as? DatabaseManager,
              //let _ = userInfo["source"] as? DataSource,
              let _ = userInfo["url"] as? NSURL
              where dbm == databaseManager else {
            log("open url notification does not contain dbm, url, or source")
            return
        }
        
        tabController.handleOpenURLNotification(notification)
    }
    
    // MARK: - Document Import
    
    @IBAction func importFiles(sender: AnyObject?) {
        guard let databaseManager = databaseManager,
              let searchService = searchService else {
            return
        }
        
        let op = NSOpenPanel()
        
        op.title = NSLocalizedString("Select folders and files. Files will be copied into the notebook.", comment: "")
        op.allowsMultipleSelection = true
        op.canChooseDirectories = false
        op.canChooseFiles = true
        
        op.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSFileHandlingPanelOKButton {
                let importer = Importer(databaseManager: databaseManager, searchService: searchService)
                importer.importFiles(op.URLs)
            }
        }
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
        guard let searchService = searchService else {
            return
        }
        guard let tab = tabController.selectedTab else {
            // just create a new tab?
            log("should always have a selected tab")
            return
        }
        guard let sender = sender as? NSSearchField else {
            log("sender can only be search field")
            return
        }
        
        let text = sender.stringValue
        
        if text == "" {
            tab.performSearch(nil, results: nil)
        } else {
            tab.performSearch(text, results: searchService.search(text))
        }
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(DocumentWindowController.performTabbedClose(_:)):
             menuItem.title = closeMenuTitle()
             return true
        case #selector(DocumentTabController.createNewMarkdownDocument(_:)),
             #selector(DocumentTabController.createNewSmartFolder(_:)),
             #selector(DocumentTabController.createNewFolder(_:)),
             #selector(DocumentTabController.makeFilesAndFoldersFirstResponder(_:)),
             #selector(DocumentTabController.makeEditorFirstResponder(_:)),
             #selector(DocumentTabController.makeFileInfoFirstResponder(_:)),
             #selector(DocumentTabController.changeLayout(_:)),
             #selector(DocumentTabController.toggleDocumentHeader(_:)):
             return tabController.validateMenuItem(menuItem)
        case #selector(DocumentWindowController.closeTab(_:)),
             #selector(DocumentTabController.createNewTab(_:)),
             #selector(DocumentTabController.selectNextTab(_:)),
             #selector(DocumentTabController.selectPreviousTab(_:)):
            return tabController.validateMenuItem(menuItem)
        case #selector(DocumentWindowController.findInNotebook(_:)),
             #selector(DocumentWindowController.closeWindow(_:)),
             #selector(DocumentWindowController.importFiles(_:)):
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
