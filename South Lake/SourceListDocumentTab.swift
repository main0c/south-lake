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
            bindEditor(selectedObjects)
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
    
    func willClose() {
        unbind("selectedObjects")
        sourceListController.willClose()
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
    
    // MARK: - Bindings
    
    func bindEditor(selection: [DataSource]) {
        if selection.count == 0 {
            clearEditor()
        } else if selection.count == 1 && selection[0] is File {
            loadEditor(selection[0] as! File)
        } else {
            // Leave editor alone if multiple selection or folder
        }
    }
    
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
            icon = selectedObjects[0].icon
        default:
            icon = nil
        }
    }
    
    // MARK: - Editor
    
    func loadEditor(file: File) {
        var editor = splitViewItems[1].viewController
        
        // Load editor if editor has changed
        
        if !(editor is MarkdownEditor) {
            editor = NSStoryboard(name: "MarkdownEditor", bundle: nil).instantiateInitialController() as! NSViewController
            let mainItem = NSSplitViewItem(viewController: editor)
        
            removeSplitViewItem(splitViewItems[1])
            insertSplitViewItem(mainItem, atIndex: 1)
        }
        
        // Pass selection to editor
    }
    
    func clearEditor() {
    
    }
}
