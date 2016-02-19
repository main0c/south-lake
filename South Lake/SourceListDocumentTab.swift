//
//  SourceListDocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class SourceListDocumentTab: NSSplitViewController, DocumentTab {
    var sourceListController: SourceListViewController!
    dynamic var icon: NSImage?
    
    var databaseManager: DatabaseManager! {
        didSet {
            for vc in childViewControllers where vc is Databasable {
                var databasable = vc as! Databasable
                databasable.databaseManager = databaseManager
            }
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
            for vc in childViewControllers where vc is Databasable {
                var databasable = vc as! Databasable
                databasable.searchService = searchService
            }
        }
    }
    
    dynamic var selectedObjects: [DataSource] = [] {
        didSet {
            bindTitle(selectedObjects)
            bindIcon(selectedObjects)
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        for vc in childViewControllers {
            switch vc {
            case let controller as SourceListViewController:
                sourceListController = controller
            default:
                break
            }
        }
        
        bind("selectedObjects", toObject: sourceListController, withKeyPath: "selectedObjects", options: [:])
        
        // Set up the editor
        
        let mainViewController = NSStoryboard(name: "MarkdownEditor", bundle: nil).instantiateInitialController() as! NSViewController
        let mainItem = NSSplitViewItem(viewController: mainViewController)
        
        closeInspector() // FIX: why close inspector first?
        
        removeSplitViewItem(splitViewItems[1])
        insertSplitViewItem(mainItem, atIndex: 1)
    }
    
    deinit {
        unbind("selectedObjects")
    }
    
    // MARK: - Document State
    
    func state() -> Dictionary<String,AnyObject> {
        return ["Title": (title ?? "")]
    }
    
    func restoreState(state: Dictionary<String,AnyObject>) {
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
    
    // MARK: - Utilities
    
    func bindTitle(selection: [DataSource]) {
        unbind("title")
        
        switch selection.count {
        case 0:
            title = NSLocalizedString("No Selection", comment: "")
        case 1:
            bind("title", toObject: selectedObjects[0], withKeyPath: "title", options: [:])
        default:
            title = NSLocalizedString("Multiple Selection", comment: "")
        }
    }
    
    func bindIcon(selection: [DataSource]) {
        unbind("icon") // icons don't really change
        
        switch selection.count {
        case 0:
            icon = nil
        case 1:
            icon = selectedObjects[0].icon ?? NSImage(named: selectedObjects[0].icon_name)
        default:
            icon = nil
        }
    }
}
