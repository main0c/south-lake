//
//  SourceListDocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class SourceListDocumentTab: NSSplitViewController, DocumentTab {
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
        
        let mainViewController = NSStoryboard(name: "MarkdownEditor", bundle: nil).instantiateInitialController() as! NSViewController
        let mainItem = NSSplitViewItem(viewController: mainViewController)
        
        closeInspector()
        
        removeSplitViewItem(splitViewItems[1])
        insertSplitViewItem(mainItem, atIndex: 1)
    }
    
    // MARK: - Document State
    
    func state() -> Dictionary<String,AnyObject> {
        return ["Title": (title ?? "")]
    }
    
    func initializeState(state: Dictionary<String,AnyObject>) {
        title = (state["Title"] ?? NSLocalizedString("Untitled", comment: "Untitled tab")) as? String
    }
    
    // MARK: - Inspector
    
    func closeInspector() {
        let mainView = splitView.subviews[1] as NSView
        let sidepanel = splitView.subviews[2] as NSView
        let viewFrame = splitView.frame
        
        sidepanel.hidden = true
        mainView.frame.size = NSMakeSize(viewFrame.size.width, viewFrame.size.height)
        splitView.display()
    }
    
    func openInspector () {
        let sidepanel = splitView.subviews[2] as NSView
        let viewFrame = splitView.frame
        
        sidepanel.hidden = false
        sidepanel.frame.size = NSMakeSize(viewFrame.size.width, 200)
        splitView.display()
    }
}
