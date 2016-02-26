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
    // Pass them onto the window's content view controller
    
    // TODO: - Maybe I just need to set up the view hierarchy correctly

    @IBAction func performTabbedClose(sender: AnyObject?) {
        guard let window = self.window else {
            return
        }
        
        if tabController.count == 1 {
            window.performClose(sender)
        } else {
            tabController.performClose(sender)
            //TODO: validate menu item
        }
    }

    @IBAction func createNewTab(sender: AnyObject?) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("createNewTab expected DocumentTabController")
            return
        }
        
        tabController.createNewTab(sender)
    }
    
    @IBAction func selectNextTab(sender: AnyObject?) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("selectNextTab expected DocumentTabController")
            return
        }
        
        tabController.selectNextTab(sender)
    }
    
    @IBAction func selectPrevousTab(sender: AnyObject?) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("selectPrevousTab expected DocumentTabController")
            return
        }
        
        tabController.selectPreviousTab(sender)
    }
    
    // MARK: User Actions
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("selectPrevousTab expected DocumentTabController")
            return
        }
        
        tabController.createNewMarkdownDocument(sender)
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        if menuItem.action == Selector("performTabbedClose:") {
            menuItem.title = tabController.count == 1
                ? NSLocalizedString("Close", comment: "Close window")
                : NSLocalizedString("Close Tab", comment: "Close tab")
        }
        
        return true
    }
    
    // MARK: - Document State
    // Primarily user interface state
    
    func state() -> Dictionary<String,AnyObject> {
        let tabState = tabController.state()
        return ["TabController": tabState]
    }
    
    func restoreState(state: Dictionary<String,AnyObject>) {
        if let tabState = state["TabController"] as? Dictionary<String,AnyObject> {
            tabController.restoreState(tabState)
        }
    }
    
}
