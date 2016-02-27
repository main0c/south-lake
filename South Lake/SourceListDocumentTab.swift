//
//  SourceListDocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: move selected object and editor loading code to default protocol implemntation

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
                if var editor = editor {
                     editor.file = (file as! File)
                }
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
        guard var editor = editor, let file = selectedObject where file is File else {
            return
        }
        editor.file = nil
    }
    
    // MARK: - Editor
    
    func loadEditor(file: File) {
        // Load editor if editor has changed
        
        if !(editor is MarkdownEditor) {
            
            // TODO: guard this, raise exception -- what?
            
            guard let editorExtension = EditorPlugIns.sharedInstance.plugInForFiletype(file.file_extension) else {
                print("unable to find editor for file with type \(file.file_extension)")
                return
            }
            
            editor = editorExtension
            let mainItem = NSSplitViewItem(viewController: (editor as! NSViewController))
        
            removeSplitViewItem(splitViewItems[1])
            insertSplitViewItem(mainItem, atIndex: 1)
            
            // addChildViewController(editor as! NSViewController)
        }
        
        // Pass selection to editor: why is var needed here for mutablily? editor is var
    }
    
    func clearEditor() {
    
    }
    
    // MARK: - User Actions
    
    // TODO: Refactoring, watch for couping to source list view controller
    
    @IBAction func createNewFolder(sender: AnyObject?) {
        // Create an untitled folder
        
        let folder = Folder(forNewDocumentInDatabase: databaseManager.database)
        folder.title = NSLocalizedString("Untitled", comment: "Name for new untitled folder")
        folder.icon = NSImage(named: "folder-icon")
        
        do { try folder.save() } catch {
            print(error)
            return
        }
        
        // Either add the folder to the Folders section or the selected folder
        
        var parent: DataSource
        var indexPath: NSIndexPath
        
        if let item = selectedObject where (item is Folder && !(item is SmartFolder)) {
            parent = item
            indexPath = sourceListController.treeController.selectionIndexPath!.indexPathByAddingIndex(parent.children.count)
        } else {
            parent = sourceListController.content[1] // Section
            indexPath = NSIndexPath(index: 1).indexPathByAddingIndex(parent.children.count)
        }
        
        parent.mutableArrayValueForKey("children").addObject(folder)
        
        do { try parent.save() } catch {
            print(error)
            return
        }
        
        sourceListController.editItemAtIndexPath(indexPath)
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject?) {
        // Create an untitled smart folder
        
        let folder = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
        folder.title = NSLocalizedString("Untitled", comment: "Name for new untitled smart folder")
        folder.icon = NSImage(named:"smart-folder-icon")
        
        do { try folder.save() } catch {
            print(error)
            return
        }
        
        // Either add the folder to the Smart Folders section or the selected folder
        
        let parent = sourceListController.content[2] // Section
        let indexPath = NSIndexPath(index: 2).indexPathByAddingIndex(parent.children.count)
        
        parent.mutableArrayValueForKey("children").addObject(folder)
        
        do { try parent.save() } catch {
            print(error)
            return
        }
        
        sourceListController.editItemAtIndexPath(indexPath)
    }
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        // Create an untitled markdown document
        
        let file = File(forNewDocumentInDatabase: databaseManager.database)
        file.title = NSLocalizedString("Untitled", comment: "Name for new untitled document")
        file.icon = NSImage(named:"markdown-document-icon")
        
        file.data = NSLocalizedString("## Untitled", comment: "New markdown document template").dataUsingEncoding(NSUTF8StringEncoding)
        
        file.uti = "net.daringfireball.markdown"
        file.file_extension = "markdown"
        file.mime_type = "text/markdown"
        
        do { try file.save() } catch {
            print(error)
            return
        }
        
        // Either add the file to the Shortcuts section or the selected folder
        
        var parent: DataSource
        var indexPath: NSIndexPath
        
        if let item = selectedObject where item is Folder {
            parent = item
            indexPath = sourceListController.treeController.selectionIndexPath!.indexPathByAddingIndex(parent.children.count)
        } else {
            parent = sourceListController.content[0] // Section
            indexPath = NSIndexPath(index: 0).indexPathByAddingIndex(parent.children.count)
        }
        
        parent.mutableArrayValueForKey("children").addObject(file)
        
        do { try parent.save() } catch {
            print(error)
            return
        }
        
        sourceListController.selectItemAtIndexPath(indexPath)
        editor?.newDocument = true
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case Selector("createNewMarkdownDocument:"),
             Selector("createNewSmartFolder:"),
             Selector("createNewFolder:"):
             return true
        default:
             break
        }
        
        return super.validateMenuItem(menuItem)
    }
}
