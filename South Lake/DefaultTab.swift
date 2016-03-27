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
///
/// CHANGES
/// The sole responbility of the tab is to watch the selection in the source list
/// and load the appropriate editor. No inspector. No header. No content view panel
///
/// The tab manages the layout. The editor/viewer manages whether it's card, table or list
/// The editor/viewer also manages a selected object, which can cause the tab to change
/// what is shown in one of the panels
///
/// The layout describes the split view structure: expanded, compact, horizontal, etc
/// The scene describes the way collection data is displayed: card, table, list.
/// Difference sources have differet storyboards for their scenes
///
/// The tab maintains a selectedSource from the source list, which could be a folder
/// or a file, as well as a selectedObject when the source is a folder that itself
/// can have a selection

enum Layout: String {
    case None
    case Expanded
    case Compact
    case Horizontal
}

enum Scene: String {
    case None
    case Card
    case Table
    case List
}

enum ViewTag: Int {
    case CompactCard = 1
    case CompactList = 2
    case CompactTable = 3
    
    case ExpandedCard = 11
    case ExpandedTable = 12
    
    case HorizontalCard = 21
    case HorizontalTable = 22
}


class DefaultTab: NSSplitViewController, DocumentTab {
    var sourceListPanel: SourceListPanel!
    var contentPanel: ContentPanel!
    // var inspectorPanel: InspectorPanel!
    
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
    
    // TODO: When you select a folder don't unbind and clear the current editor, Whether we unbind depends on on what is being bound?
    // TODO: We may not route all of this through selectedObjects. It's convenient
    //       because title and icon bindings are already set up to work with it,
    //       but that's all really and can easily enough be duplicated
    
    /// The selected source list objects originate in the source list and are
    /// displayed in the second panel
    
    dynamic var selectedSourceListObjects: [DataSource] = [] {
        didSet {
            selectedObjects = selectedSourceListObjects
        }
    }
    
    /// The selected file objects originate in the source viewer being shown for
    /// the currently selected source list objects and are displayed in either
    /// the second or third panel
    
    dynamic var selectedFileObjects: [DataSource] = [] {
        didSet {
            selectedObjects = selectedFileObjects
        }
    }
    
    /// ...
    
    dynamic var selectedURLObjects: [DataSource] = [] {
        didSet {
            selectedObjects = selectedURLObjects
        }
    }
    
    dynamic var selectedObjects: [DataSource] = [] {
        willSet {
            unbindTitle(selectedObjects)
            unbindIcon(selectedObjects)
            
            // unbindEditor(selectedObjects)
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
    
    var layoutController: NSSplitViewController!
    var sourceViewer: SourceViewer?
   
    var header: FileHeaderViewController?
    var editor: SourceViewer?
    
    var inspectors: [Inspector]?
    
    //
    
    var layout: Layout = .None {
        didSet {
            if layout != oldValue {
                loadLayout(layout)
            }
        }
    }
    var scene: Scene = .None {
        didSet {
            if scene != oldValue {
                sourceViewer?.scene = scene
            }
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Acquire child view controllers
        
        for vc in childViewControllers {
            switch vc {
            case let controller as SourceListPanel:
                sourceListPanel = controller
//            case let controller as InspectorPanel:
//                inspectorPanel = controller
            default:
                break
            }
        }
        
        // TODO: can't use notification center: can, just make sure we're passing the dbm
        // TODO: Set up the initial editor?
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("documentWillSave:"), name: DocumentWillSaveNotification, object: nil)
        
        bind("selectedSourceListObjects", toObject: sourceListPanel, withKeyPath: "selectedObjects", options: [:])
        
        // Load the layout controller

        layoutController = storyboard!.instantiateControllerWithIdentifier("Layout") as? NSSplitViewController
        replaceSplitViewItem(atIndex: 1, withViewController: layoutController!)
        
        // Create the content panel and move it into place
        
        contentPanel = ContentPanel()
        contentPanel.view = NSView(frame: CGRectZero)
        
        if layoutController.splitViewItems.count >= 2 {
            layoutController.replaceSplitViewItem(atIndex: 1, withViewController: contentPanel)
        }
        
        // Restore user layout preferences
        
        if  let savedValue = NSUserDefaults.standardUserDefaults().stringForKey("SLLayout"),
            let savedLayout = Layout(rawValue: savedValue) {
            layout = savedLayout
        } else {
            layout = .Compact
        }
        
        if  let savedValue = NSUserDefaults.standardUserDefaults().stringForKey("SLScene"),
            let savedScene = Scene(rawValue: savedValue) {
            scene = savedScene
        } else {
            scene = .Card
        }
    }
    
    func willClose() {
        sourceListPanel.willClose()
//        inspectorPanel.willClose()
        contentPanel.willClose()
        
        unbindTitle(selectedObjects)
        unbindIcon(selectedObjects)
        
        unbind("selectedFileObjects")
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
    
    // MARK: - Layout
    
    func loadLayout(identifier: Layout) {
    
        // Preserve the existing divider position
        // TODO: save vertical and horizontal sizes and ensure we have enough room for the change
    
        let position = layoutController.splitView.vertical
            ? layoutController.splitViewItems[0].viewController.view.frame.size.width
            : layoutController.splitViewItems[0].viewController.view.frame.size.height
    
        // Determine if the layout is vertical
    
        var vertical = true
        
        switch identifier {
        case .Compact, .Expanded:
            vertical = true
        case .Horizontal:
            vertical = false
        default:
            vertical = true
        }
        
        layoutController!.splitView.vertical = vertical
        layoutController!.splitView.adjustSubviews()
        layoutController!.splitView.setPosition(position, ofDividerAtIndex: 0)
        
        
        
//        layoutController = storyboard!.instantiateControllerWithIdentifier(identifier.rawValue) as? NSSplitViewController
//        guard let layoutController = layoutController else {
//            log("unable to load layout \(identifier)")
//            return
//        }
//        
//        replaceSplitViewItem(atIndex: 1, withViewController: layoutController)
//        
//        // Preserve currently visible source and file viewers
//        // TODO: if we're moving from two panes to one pane, preserve the file viewer instead of the source viewer
//        
//        if sourceViewer != nil && splitViewItems.count >= 1 {
//            layoutController.replaceSplitViewItem(atIndex: 0, withViewController: sourceViewer as! NSViewController)
//        }
//        
//        // TODO: replace the content panel, not the editor
//        
//        if splitViewItems.count >= 2 {
//            layoutController.replaceSplitViewItem(atIndex: 1, withViewController: contentPanel)
//        }
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
        
        // TODO: changes to the source list will need the editor cleared as well
        // TODO: when loading a file from the source list we always need to display in expanded view
        // TODO: some sources won't support all views: calendar, tags...
        
        // Breaking on no selection in order to preserve the editor across changes to the scene
        
        switch (selection.count, item) {
        case (0, _):
            break
        case (1, is File):
            loadEditor(item!)
        case (1, is Folder):
            loadSource(item!)
        case (_,_):
            break
        }
    }
      
//    func unbindEditor(selection: [DataSource]) {
//        guard let editor = editor else {
//            return
//        }
//        editor.source = nil
//    }
    
    /// Loads a new file editor iff it has changed
    
    func loadEditor(file: DataSource) {
        guard editor?.source != file else {
            return
        }
        guard editor == nil || !editor!.dynamicType.filetypes.contains(file.uti) else {
            editor!.source = file
            return
        }
        
        // Acquire a new editor
        
        clearEditor()
        editor = EditorPlugIns.sharedInstance.plugInForFiletype(file.file_extension)
        
        guard editor != nil else {
            log("unable to find editor for file with type \(file.file_extension)")
            clearEditor()
            return
        }
        
        // Prepare the editor
        
        editor!.databaseManager = databaseManager
        editor!.searchService = searchService
        editor!.source = file
        
        // Move the editor into place
    
        contentPanel.editor = editor
    }
    
    func clearEditor() {
        editor?.willClose()
        // editor?.source = nil
        // contentPanel.editor = nil
        editor = nil
    }
    
    /// Loads a new source viewer iff it has changed
    
    func loadSource(source: DataSource) {
        guard sourceViewer == nil || !sourceViewer!.dynamicType.filetypes.contains(source.uti) else {
            sourceViewer!.source = source
            return
        }
        
        // Acquire a new source viewer
        
        sourceViewer?.willClose()
        sourceViewer = EditorPlugIns.sharedInstance.plugInForFiletype(source.file_extension)
        
        guard sourceViewer != nil else {
            log("unable to find editor for file with type \(source.file_extension)")
            clearSource()
            return
        }
        
        // Prepare the source viewer
        
        sourceViewer!.databaseManager = databaseManager
        sourceViewer!.searchService = searchService
        sourceViewer!.source = source
        sourceViewer!.scene = scene
        
        // Move the source viewer into place
        
        guard let layoutController = layoutController else {
            log("layout controller unavailable")
            return
        }
        
        layoutController.replaceSplitViewItem(atIndex: 0, withViewController: sourceViewer as! NSViewController)
        
        // Establish connections
        
        bind("selectedFileObjects", toObject: sourceViewer!, withKeyPath: "selectedObjects", options: [:])
    }
    
    func clearSource() {
        unbind("selectedFileObjects")
        sourceViewer?.willClose()
        sourceViewer = nil
    }
    
    // MARK: - Header
    
    func bindHeader(selection: [DataSource]) {
        let item = selectedObject
        
        switch (selection.count, item) {
//        case (0, _): clearHeader()
        case (1, is File): loadHeader(item!)
//        case (1, is Folder): clearHeader()
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
//            clearHeader()
            return
        }
        
        if ( header == nil ) {
            header = NSStoryboard(name: "FileHeader", bundle: nil).instantiateInitialController() as? FileHeaderViewController
            
            header?.databaseManager = databaseManager
            header?.searchService = searchService
            
            contentPanel.header = header
            
            // Next responder: tab from title to editor
            header?.primaryResponder.nextKeyView = editor?.primaryResponder
        }
        
        header!.file = file
    }
    
//    func clearHeader() {
//        contentPanel.header = nil
//        header = nil
//    }
    
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
//        inspectorPanel.inspectors = nil
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
        
//        inspectorPanel.inspectors = inspectors
    }
    
    func loadInspectorForMultipleSelection(files: [DataSource]) {
    
    }
    
    // MARK: - Search
    
    func performSearch(text: String?, results: BRSearchResults?) {
        guard let library = databaseManager?.librarySource else {
            return
        }
        
        sourceListPanel.selectItem(library)
        editor?.performSearch(text, results: results)
    }
    
    // MARK: - User Actions
    
    ///Create an untitled folder
    @IBAction func createNewFolder(sender: AnyObject?) {
        guard let databaseManager = databaseManager,
              let folders = databaseManager.foldersSection else {
            return
        }
        
        let folder = Folder(forNewDocumentInDatabase: databaseManager.database)
        folder.title = NSLocalizedString("Untitled", comment: "Name for new untitled folder")
        folder.icon = NSImage(named: "folder-icon")
        
        do { try folder.save() } catch {
            log(error)
            return
        }
        
        // Either add the folder to the Folders section or the selected folder
        // Can use item or index path, but the index path should be faster
        
//        var parent: DataSource
//        var indexPath: NSIndexPath
//        
//        if  let selectedIndexPath = sourceListPanel.selectedIndexPath,
//            let item = selectedObject where item.uti == DataTypes.Folder.uti {
//            parent = item
//            indexPath = selectedIndexPath.indexPathByAddingIndex(parent.children.count)
//        } else {
//            parent = folders
//            indexPath = NSIndexPath(index: folders.index).indexPathByAddingIndex(parent.children.count)
//        }
        
        // Actually disallow subfolders for now
        
        let parent = folders
        let indexPath = NSIndexPath(index: folders.index).indexPathByAddingIndex(parent.children.count)
        
        parent.mutableArrayValueForKey("children").addObject(folder)
        
        do { try parent.save() } catch {
            log(error)
            return
        }
        
        sourceListPanel.editItemAtIndexPath(indexPath)
        // sourceListPanel.selectItem(folder)
    }
    
    /// Create an untitled smart folder
    @IBAction func createNewSmartFolder(sender: AnyObject?) {
        guard let databaseManager = databaseManager,
              let smartFolders = databaseManager.smartFoldersSection else {
            return
        }
        
        let folder = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
        folder.title = NSLocalizedString("Untitled", comment: "Name for new untitled smart folder")
        folder.icon = NSImage(named:"smart-folder-icon")
        
        do { try folder.save() } catch {
            log(error)
            return
        }
        
        // Either add the folder to the Smart Folders section or the selected folder
        // Can use item or index path, but the index path should be faster
        
        let parent = smartFolders
        let indexPath = NSIndexPath(index: smartFolders.index).indexPathByAddingIndex(parent.children.count)
        
        parent.mutableArrayValueForKey("children").addObject(folder)
        
        do { try parent.save() } catch {
            log(error)
            return
        }
        
        sourceListPanel.editItemAtIndexPath(indexPath)
    }
    
    /// Create an untitled markdown document
    @IBAction func createNewMarkdownDocument(sender: AnyObject?) {
        guard let databaseManager = databaseManager,
              let folders = databaseManager.foldersSection else {
            return
        }
        
        let file = File(forNewDocumentInDatabase: databaseManager.database)
        file.title = NSLocalizedString("Untitled", comment: "Name for new untitled document")
        file.icon = NSImage(named:"markdown-document-icon")
        
        file.uti = "net.daringfireball.markdown"
        file.file_extension = "markdown"
        file.mime_type = "text/markdown"
        
        do { try file.save() } catch {
            log(error)
            return
        }
        
        // Either add the file to the Folders section or the selected folder
        // Can use item or index path, but the index path should be faster
        
        var parent: DataSource
        var indexPath: NSIndexPath
        
        if  let selectedIndexPath = sourceListPanel.selectedIndexPath,
            let item = selectedObject where item.uti == DataTypes.Folder.uti {
            parent = item
            indexPath = selectedIndexPath.indexPathByAddingIndex(parent.children.count)
        } else {
            parent = folders
            indexPath = NSIndexPath(index: folders.index).indexPathByAddingIndex(parent.children.count)
        }
        
        parent.mutableArrayValueForKey("children").addObject(file)
        
        do { try parent.save() } catch {
            log(error)
            return
        }
        
        sourceListPanel.selectItemAtIndexPath(indexPath)
        // sourceListPanel.selectItem(file)
    }
    
    @IBAction func makeFilesAndFoldersFirstResponder(sender: AnyObject?) {
        self.view.window?.makeFirstResponder(sourceListPanel.primaryResponder)
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
    
    @IBAction func changeLayout(sender: AnyObject?) {
        guard let sender = sender as? NSPopUpButton else {
            log("sender must be a popup button")
            return
        }
        guard let tag = ViewTag(rawValue: sender.selectedTag()) else {
            log("invalid tag")
            return
        }
        
        // Extract options

        switch tag {
        case ViewTag.CompactCard:
            layout = Layout.Compact
            scene = Scene.Card
        case ViewTag.CompactList:
            layout = Layout.Compact
            scene = Scene.List
        case ViewTag.CompactTable:
            layout = Layout.Compact
            scene = Scene.Table
        case ViewTag.ExpandedCard:
            layout = Layout.Expanded
            scene = Scene.Card
        case ViewTag.ExpandedTable:
            layout = Layout.Expanded
            scene = Scene.Table
        case ViewTag.HorizontalCard:
            layout = Layout.Horizontal
            scene = Scene.Card
        case ViewTag.HorizontalTable:
            layout = Layout.Horizontal
            scene = Scene.Table
        }
        
        // Save setting
        
        NSUserDefaults.standardUserDefaults().setObject(layout.rawValue, forKey: "SLLayout")
        NSUserDefaults.standardUserDefaults().setObject(scene.rawValue, forKey: "SLScene")
    }
    
    // MARK: -
    
    func handleOpenURLNotification(notification: NSNotification) {
        guard let userInfo = notification.userInfo,
              let dbm = userInfo["dbm"] as? DatabaseManager,
              //let source = userInfo["source"] as? DataSource,
              let url = userInfo["url"] as? NSURL
              where dbm == databaseManager else {
            log("open url notification does not contain dbm or url")
            return
        }
        
        guard let library = databaseManager?.librarySource,
              let tags = databaseManager?.tagsSource else {
            return
        }
        
        // TODO: examine the url to decide what primary source to select
        // TODO: Switch up that switch statement to case on a tuple
        
        log(url.pathComponents)
        
        guard let root = url.pathComponents?[safe: 1] else {
            log("no root path in url \(url)")
            return
        }
        
        switch root {
        case "library":
            // Select library, pass open url to library editor?
            sourceListPanel.selectItem(library)
            if let source = userInfo["source"] as? DataSource { // guard
                selectedURLObjects = [source]
            }
            editor?.openURL(url)
        case "tags":
            sourceListPanel.selectItem(tags)
            editor?.openURL(url)
        case _:
            log(root)
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
             Selector("makeFileInfoFirstResponder:"),
             Selector("changeLayout:"):
             return true
        default:
             return false
        }
    }
}
