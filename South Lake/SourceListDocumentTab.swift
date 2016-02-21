//
//  SourceListDocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

private var SourceListDocumentTabContext = 0

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
    
    deinit {
        // TODO: may need to unbind editor
        
    }

    // TODO: track editor
    // TOOD: save when changing selection
    
    func documentWillSave(notification: NSNotification) {
        guard selectedObjects.count == 1 else {
            return
        }
        guard let file = selectedObject as? File where selectedObject is File else {
            return
        }
        guard let data = (splitViewItems[1].viewController as! FileEditor).data else {
            return
        }
        
        // And if data is nil? do we still set it?
        
        file.data = data
    }
    
    func willClose() {
        unbind("selectedObjects")
        sourceListController.willClose()
        
        // TODO: data-bindings or kvo
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
    
    // A single file may be handled by more than one editor at a time
    // But a single editor will only handle a single file at a time
    
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
                
                // KVO:
                // bind editor to file's data (one editor binding at a time)
                // but watch for changes to editor to propogate back to data?
                
                (editor as! NSViewController).addObserver(self, forKeyPath: "data", options: [.New, .Old], context: &SourceListDocumentTabContext)
                
                (file as! File).addObserver(self, forKeyPath: "data", options: [.New, .Old], context:&SourceListDocumentTabContext)
                
            } else {
            // Leave editor alone if multiple selection or folder
            // Unbind? no... Xcode does not
            }
        default:
            // Leave editor alone if multiple selection or folder
            // Unbind? no... Xcode does not
            break
        }
        
        if selection.count == 0 {
            clearEditor()
        } else if selection.count == 1 && selection[0] is File {
            loadEditor(selection[0] as! File)
        } else {
            // Leave editor alone if multiple selection or folder
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
        if let editor = editor {
            (editor as! NSViewController).removeObserver(self, forKeyPath: "data")
        }
        if let file = selectedObject where file is File {
            (file as! File).removeObserver(self, forKeyPath: "data")
        }
    }
    
    // MARK: -
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        guard context == &SourceListDocumentTabContext else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
            return
        }
        
        guard keyPath == "data" else {
            return
        }
        guard editor != nil else {
            return
        }
        guard let file = selectedObject where file is File else {
            return
        }
        guard let change = change,
              let oldValue = change[NSKeyValueChangeOldKey] as? NSData,
              let newValue = change[NSKeyValueChangeNewKey] as? NSData
              where !oldValue.isEqualToData(newValue) else {
            return
        }
        
        if object is FileEditor {
            (file as! File).data = editor!.data
        } else if object is File {
            editor!.data = (file as! File).data
        }
        
        print("data kvo")
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
    
        editor!.data = file.data
    }
    
    func clearEditor() {
    
    }
}
