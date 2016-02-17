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

class DocumentWindowController: NSWindowController {
    var databaseManager: DatabaseManager! {
        didSet {
            if let contentController = self.window?.contentViewController as? DocumentTabController {
                contentController.databaseManager = databaseManager
            }
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
            if let contentController = self.window?.contentViewController as? DocumentTabController {
                contentController.searchService = searchService
            }
        }
    }
    
    override func windowDidLoad() {
        super.windowDidLoad()
    
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }
    
    // Tab actions: pass them onto the window's content view controller

    @IBAction func createNewTab(sender: AnyObject) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("createNewTab expected DocumentTabController")
            return
        }
        
        tabController.createNewTab(sender)
    }
    
    @IBAction func selectNextTab(sender: AnyObject) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("selectNextTab expected DocumentTabController")
            return
        }
        
        tabController.selectNextTab(sender)
    }
    
    @IBAction func selectPrevousTab(sender: AnyObject) {
        guard let tabController = self.window?.contentViewController as? DocumentTabController else {
            print("selectPrevousTab expected DocumentTabController")
            return
        }
        
        tabController.selectPreviousTab(sender)
    }
    
}
