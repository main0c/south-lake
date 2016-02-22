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
        willSet {
            unbindEditor(selectedObjects)
            unbindTitle(selectedObjects)
            unbindIcon(selectedObjects)
        }
        didSet {
            bindEditor(selectedObjects)
            bindTitle(selectedObjects)
            bindIcon(selectedObjects)
            
        }
    }
    
    var selectedObject: DataSource? {
        return ( selectedObjects.count == 1 ) ? selectedObjects[0] : nil
    }
    
    var editor: FileEditor?
    
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
        
        // TODO: can't use notification center
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("documentWillSave:"), name: DocumentWillSaveNotification, object: nil)
        
        bind("selectedObjects", toObject: sourceListController, withKeyPath: "selectedObjects", options: [:])
        
        // Set up the editor
        
        let mainViewController = NSStoryboard(name: "MarkdownEditor", bundle: nil).instantiateInitialController() as! NSViewController
        let mainItem = NSSplitViewItem(viewController: mainViewController)
        
        closeInspector() // FIX: why close inspector first?
        
        removeSplitViewItem(splitViewItems[1])
        insertSplitViewItem(mainItem, atIndex: 1)
    }
    
    // TOOD: save when changing selection
    
    func documentWillSave(notification: NSNotification) {
    
    }
    
    func willClose() {
        unbindEditor(selectedObjects)
        unbindTitle(selectedObjects)
        unbindIcon(selectedObjects)
        
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
    
    // File.data <-> Editor one-to-many two-way bindings
    
    // A single file may be handled by more than one editor
    // A single editor handles a single file
    
    // An editor makes a change, it propogates to the file, and from there
    // it must propogate to every other editor working with that file
    
    // Use KVO to manage these changes
    
    func bindEditor(selection: [DataSource]) {
        let file = selectedObject
        
        switch selection.count {
        case 0:
           clearEditor()
        case 1: // where file is File:
            if file is File {
                loadEditor(file as! File)
                editor!.data = (file as! File).data
                (editor as! NSObject).bindUs("data", toObject: (file as! File), withKeyPath: "data", options: [:])
            } else {
            // Leave editor alone if multiple selection or folder
            // Unbind? no... Xcode does not
            }
        default:
            // Leave editor alone if multiple selection or folder
            // Unbind? no... Xcode does not
            break
        }
    }
    
    func bindTitle(selection: [DataSource]) {
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
        switch selection.count {
        case 0:
            icon = nil
        case 1:
            icon = selectedObjects[0].icon
        default:
            icon = nil
        }
    }
    
    func unbindTitle(selection: [DataSource]) {
        unbind("title")
    }
    
    func unbindIcon(selection: [DataSource]) {
        unbind("icon")
    }
    
    func unbindEditor(selection: [DataSource]) {
        guard let editor = editor, let file = selectedObject where file is File else {
            return
        }
        
        (editor as! NSObject).unbindUs("data", toObject: file, withKeyPath: "data")
    }
    
    // MARK: - Editor
    
    func loadEditor(file: File) {
        // Load editor if editor has changed
        
        if !(editor is MarkdownEditor) {
            editor = NSStoryboard(name: "MarkdownEditor", bundle: nil).instantiateInitialController() as? FileEditor
            let mainItem = NSSplitViewItem(viewController: (editor as! NSViewController))
        
            removeSplitViewItem(splitViewItems[1])
            insertSplitViewItem(mainItem, atIndex: 1)
        }
        
        // Pass selection to editor: why is var needed here for mutablily? editor is var
    }
    
    func clearEditor() {
    
    }
}
