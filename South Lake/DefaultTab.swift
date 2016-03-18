//
//  DefaultTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: move selected object and editor loading code to default protocol implemntation

import Cocoa

/// The Default Tab coordinates between selection in the source list and the creation
/// and destruction Editor-Inspectors, which it passes to the content and inspector controllers
/// A metadata inspector appears for multiple file selection, and this object must watch
/// for multiple selection and change the content and inspectors accordingly
///
/// Most importantly, the Tab maintains bindings that sync selection across view controlelrs
/// and which sync the model to the interface
///
/// The Tab also watches for changes in file viewer editors (library, etc) so that the metadata
/// inspectors can be updated. A Tab can also be informed when an editor wants to open a file
/// and open it in place
///
/// The Tab maintains a selection history of that provides enough information to recall the
/// selection in the source list as well as selection changes in an editor. I guess we'll see
/// about that.

class DefaultTab: NSSplitViewController, DocumentTab {
    var sourceListController: SourceListPanel!     // left data source
    var contentController: ContentViewPanel! // center content
    var inspectorController: InspectorPanel! // right inspector
    
    // Default inspectors
    
    // ...
    
    dynamic var icon: NSImage?
    
    // MARK: - Document Tab
    
    var databaseManager: DatabaseManager? {
        didSet {
            for vc in childViewControllers where vc is Databasable {
                var databasable = vc as! Databasable
                databasable.databaseManager = databaseManager
            }
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            for vc in childViewControllers where vc is Databasable {
                var databasable = vc as! Databasable
                databasable.searchService = searchService
            }
        }
    }
    
    // TODO: When you select a folder don't unbind and clear the current editor
    // Whether we unbind depends on on what is being bound
    
    dynamic var selectedSourceListObjects: [DataSource] = [] {
        didSet {
            selectedObjects = selectedSourceListObjects
        }
    }
    
    dynamic var selectedURLObjects: [DataSource] = [] {
        didSet {
            selectedObjects = selectedURLObjects
        }
    }
    
    dynamic var selectedObjects: [DataSource] = [] {
        willSet {
            unbindTitle(selectedObjects)
            unbindIcon(selectedObjects)
            
            unbindEditor(selectedObjects)
            unbindHeader(selectedObjects)
            unbindInspectors(selectedObjects)
        }
        didSet {
            selectedObject = selectedObjects[safe:0]
            
            bindTitle(selectedObjects)
            bindIcon(selectedObjects)
            
            bindEditor(selectedObjects)
            bindHeader(selectedObjects)
            bindInspectors(selectedObjects)
        }
    }
    
    dynamic var selectedObject: DataSource?
   
    var inspectors: [Inspector]?
    var header: FileHeaderViewController?
    var editor: FileEditor?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // self.view.translatesAutoresizingMaskIntoConstraints = false
        
        // Acquire child view controllers
        
        for vc in childViewControllers {
            switch vc {
            case let controller as SourceListPanel:
                sourceListController = controller
                break
            case let controller as ContentViewPanel:
                contentController = controller
                break
            case let controller as InspectorPanel:
                inspectorController = controller
            default:
                break
            }
        }
        
        // TODO: can't use notification center: can, just make sure we're passing the dbm
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("documentWillSave:"), name: DocumentWillSaveNotification, object: nil)
        
        bind("selectedSourceListObjects", toObject: sourceListController, withKeyPath: "selectedObjects", options: [:])
        
        // TODO: Set up the initial editor?

    }
    
    func willClose() {
        sourceListController.willClose()
        inspectorController.willClose()
        contentController.willClose()
        
        unbindTitle(selectedObjects)
        unbindIcon(selectedObjects)
        unbind("selectedSourceListObjects")
        
        if let inspectors = inspectors {
            for inspector in inspectors {
                inspector.willClose()
                switch inspector {
                case let i as RelatedInspector:
                    i.unbind("selectedObjects")
                case _:
                    break
                }
            }
        }
    }
        
    // TOOD: save when changing selection
    
    func documentWillSave(notification: NSNotification) {
    
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
    
    func bindTitle(selection: [DataSource]) {
        let count = selection.count
        
        switch count {
        case 0:
            title = NSLocalizedString("No Selection", comment: "")
        case 1:
            bind("title", toObject: selectedObjects[0], withKeyPath: "title", options: [:])
        default:
            title = NSLocalizedString("Multiple Selection", comment: "")
        }
    }
    
    func bindIcon(selection: [DataSource]) {
        let count = selection.count
        
        switch count {
        case 0:
            icon = nil
        case 1:
            bind("icon", toObject: selectedObjects[0], withKeyPath: "icon", options: [:])
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
    
    // MARK: - Editor
    
    func bindEditor(selection: [DataSource]) {
        let item = selectedObject
        
        switch (selection.count, item) {
        case (0, _): clearEditor()
        case (1, is File): loadEditor(item!)
        case (1, is Folder): loadEditor(item!) // in most cases we'll want to clear the editor here
        case (_,_): break
        }
    }
      
    func unbindEditor(selection: [DataSource]) {
        guard let editor = editor else {
            return
        }
        editor.file = nil
    }
    
    func loadEditor(file: DataSource) {
        // Load editor if editor has changed
        
        if editor == nil || !editor!.dynamicType.filetypes.contains(file.uti) {
            editor?.willClose() // TODO: move to willSet?
            editor = EditorPlugIns.sharedInstance.plugInForFiletype(file.file_extension)
            
            guard editor != nil else {
                print("unable to find editor for file with type \(file.file_extension)")
                clearEditor()
                return
            }

            contentController.editor = editor
            
            // Prepare the new editor
            
            editor!.databaseManager = databaseManager
            editor!.searchService = searchService
         }
        
        // Always pass selection to the editor
        
        editor!.file = file
    }
    
    func clearEditor() {
        editor?.willClose() // TODO: move to willSet?
        contentController.editor = nil
        editor = nil
    }
    
    // MARK: - Header
    
    func bindHeader(selection: [DataSource]) {
        let item = selectedObject
        
        switch (selection.count, item) {
        case (0, _): clearHeader()
        case (1, is File): loadHeader(item!)
        case (1, is Folder): clearHeader()
        case (_,_): break
        }
    }
    
    func unbindHeader(selection:[DataSource]) {
        guard let header = header else {
            return
        }
        header.file = nil
    }
    
    func loadHeader(file: DataSource) {
        // It's possible this file does not show a header
        
        guard editor != nil && editor!.isFileEditor else {
            clearHeader()
            return
        }
        
        if ( header == nil ) {
            header = NSStoryboard(name: "FileHeader", bundle: nil).instantiateInitialController() as? FileHeaderViewController
            
            header?.databaseManager = databaseManager
            header?.searchService = searchService
            
            contentController.header = header
            
            // Next responder: tab from title to editor
            header?.primaryResponder.nextKeyView = editor?.primaryResponder
        }
        
        header!.file = file
    }
    
    func clearHeader() {
        contentController.header = nil
        header = nil
    }
    
    // MARK: - Inspector
    
    func bindInspectors(selection: [DataSource]) {
        // For multiple selection, the tab manages a metadata inspector view and bindings
        // For single file selection, the file editor has the inspectors and we add metadata
        // For single folder selection, no inspector (or folder metadata?)
        // For no selector: no inspector
        
        let item = selectedObject
        
        switch (selection.count, item) {
        case (0, _): clearInspector()
        case (1, is File): loadInspector(item!)
        case (1, is Folder): loadInspector(item!)
        case (_,_): loadInspectorForMultipleSelection(selection)
        }
    }
    
    func unbindInspectors(selection: [DataSource]) {
        // For single selection, do nothing. The editor handles inspector bindings
        // For multiple selection or inspectors the tab has created, unbind the inspectors
        
        if let inspectors = inspectors {
            for inspector in inspectors {
                inspector.willClose()
                switch inspector {
                case let i as RelatedInspector:
                    i.unbind("selectedObjects")
                case _:
                    break
                }
            }
        }
    }
    
    func clearInspector() {
        inspectorController.inspectors = nil
        inspectors = nil
    }
    
    func loadInspector(file: DataSource) {
        guard let editor = editor else {
            clearInspector()
            return
        }
        
        // TODO: only reload inspectors if they are different
        // Don't need to set up bindings or pass files because they are taken care of by the editor
        
        inspectors = editor.inspectors
        
        // Test
        
        inspectors = inspectors ?? []
        
        let metadataInspector = NSStoryboard(name: "MetadataInspector", bundle: nil).instantiateInitialController() as! MetadataInspector
        let commentsInspector = NSStoryboard(name: "CommentsInspector", bundle: nil).instantiateInitialController() as! CommentsInspector
        let relatedInspector = NSStoryboard(name: "RelatedInspector", bundle: nil).instantiateInitialController() as! RelatedInspector
        
        metadataInspector.databaseManager = databaseManager
        commentsInspector.databaseManager = databaseManager
        relatedInspector.databaseManager = databaseManager
        
        metadataInspector.searchService = searchService
        commentsInspector.searchService = searchService
        relatedInspector.searchService = searchService
        
        // TODO: we don't always need to be rebuilding and rebinding these things, file insepctors
        // that are permanently available should just stick around
        
        relatedInspector.bind("selectedObjects", toObject: self, withKeyPath: "selectedObjects", options: [:])
        
        inspectors!.append(metadataInspector)
        inspectors!.append(commentsInspector)
        inspectors!.append(relatedInspector)
        
        inspectorController.inspectors = inspectors
    }
    
    func loadInspectorForMultipleSelection(files: [DataSource]) {
    
    }
    
    // MARK: - Search
    
    func performSearch(text: String?, results: BRSearchResults?) {
        // Get the library and select it: 
        // TODO: cannot hardcode this
        
        let indexPath = NSIndexPath(indexes: [0,0], length: 2)
        
        sourceListController.selectItemAtIndexPath(indexPath)
        editor?.performSearch(text, results: results)
    }
    
    // MARK: - User Actions
    
    // TODO: Refactoring, watch for coupling to source list view controller
    
    ///Create an untitled folder
    @IBAction func createNewFolder(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        
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
    
    /// Create an untitled smart folder
    @IBAction func createNewSmartFolder(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        
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
    
    /// Create an untitled markdown document
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        
        let file = File(forNewDocumentInDatabase: databaseManager.database)
        file.title = NSLocalizedString("Untitled", comment: "Name for new untitled document")
        file.icon = NSImage(named:"markdown-document-icon")
        
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
        
        // editor?.newDocument = true
    }
    
    @IBAction func makeFilesAndFoldersFirstResponder(sender: AnyObject?) {
        self.view.window?.makeFirstResponder(sourceListController.primaryResponder)
    }
    
    @IBAction func makeEditorFirstResponder(sender: AnyObject?) {
        guard let editor = editor else {
            NSBeep()
            return
        }
        self.view.window?.makeFirstResponder(editor.primaryResponder)
    }
    
    @IBAction func makeFileInfoFirstResponder(sender: AnyObject?) {
        NSBeep()
    }
    
    // MARKL -
    
    func handleOpenURLNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let dbm = userInfo["dbm"] as? DatabaseManager,
              //let source = userInfo["source"] as? DataSource,
              let url = userInfo["url"] as? NSURL
              where dbm == databaseManager else {
            print("open url notification does not contain dbm or url")
            return
        }
        
        // TODO: examine the url to decide what primary source to select
        // TODO: Switch up that switch statement to case on a tuple
        // TODO: really can't hardcode index paths!
        
        print(url.pathComponents)
        
        guard let root = url.pathComponents?[safe: 1] else {
            print("no root path in url \(url)")
            return
        }
        
        switch root {
        case "library":
            // Select library, pass open url to library editor?
            sourceListController.selectItemAtIndexPath(NSIndexPath(indexes: [0,0], length: 2))
            if let source = userInfo["source"] as? DataSource { // guard
                selectedURLObjects = [source]
            }
            editor?.openURL(url)
        case "tags":
            // Select tags, pass open url to tags editor
            sourceListController.selectItemAtIndexPath(NSIndexPath(indexes: [0,2], length: 2))
            editor?.openURL(url)
        case _:
            print(root)
        }
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case Selector("createNewMarkdownDocument:"),
             Selector("createNewSmartFolder:"),
             Selector("createNewFolder:"),
             Selector("makeFilesAndFoldersFirstResponder:"),
             Selector("makeEditorFirstResponder:"),
             Selector("makeFileInfoFirstResponder:"):
             return true
        default:
             return false
        }
    }
}
