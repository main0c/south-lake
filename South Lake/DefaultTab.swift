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

// TODO: document all the interactions between source list selectioned, source 
//       viewer selection, layout, and editor centralize effects of that 
//       relationships

// TODO: Fix this shit. Too much going on, too many interactions. What I want is 
//       to map events to state declaratively. given event x produce ui y.
//       Instead I'm changing ui state all over the place

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

/// The default tab consists of a two panel split view. The left panel contains a source list
/// and the initially selectable content, including files, folders and other shortcuts.

/// The second panel contains an embedded split view that is also two panels. The first
/// panel displays source list content when that content is selectble (e.g. a folder's files,
/// the library, a list of tags, the calendar).

/// The second panel displays one of three contents: an empty selection message, the content panel
/// which manages the placement of the header, editor, and inspectors, or an editor by itself
/// when it is also selectable.

class DefaultTab: NSSplitViewController, DocumentTab {
    
    /// The source list panel is displayed on the far left and contains the primary selectable objects
    
    var sourceListPanel: SourceListPanel!
   
    /// The layout controller manages a split view embedded in the second panel of the primary split view
    /// It is also two panels: the first shows collection content for whatever is selected in the source 
    /// list panel. The second shows either a no selection message, additional collection content, or an 
    /// actual file.
   
    var layoutController: NSSplitViewController!
    
    /// The content panel appears in the second panel of the layout controller and 
    /// manages the placement of the header, a file source viewer and inspectors.
    /// It is used for file content and is moved in and out of its parent split view
    
    var contentPanel: ContentPanel?
    
    /// The no selection panel appears in the second panel of the layout controller
    /// when there is no right source viewer to display
    
    var noSelectionPanel: NSViewController?
    
    /// The left source viewer appears in the first panel of the layout controller
    /// and is used for selectable content, e.g. a folder's file list, tag list, calendar, etc
    
    var leftSourceViewer: SourceViewer?
    
    /// The right source viewer appears in the second panel of the layout controller
    /// and is used both for selectable content, for example when a tag is selected in the
    /// tag list and files associated with that tag are shown, and for content that cannot be selected,
    /// e.g. a file. When the right source viewer is a file, it is embedded in the content panel
    
    var rightSourceViewer: SourceViewer?
    
    /// Inspectors appear only with file contents but the variable is currently unused
    
    var inspectors: [Inspector]?
    // var inspectorPanel: InspectorPanel!
    
    // MARK: - Document Tab
    
    /// A document tab must have an icon. It is used by the tab controller and displayed
    /// in the tab bar.
    
    dynamic var icon: NSImage?
    
    var databaseManager: DatabaseManager? {
        didSet {
            for vc in childViewControllers where vc is Databasable {
                var databasable = vc as! Databasable
                databasable.databaseManager = databaseManager
            }
            contentPanel?.header.databaseManager = databaseManager
        }
    }
    
    var searchService: BRSearchService? {
        didSet {
            for vc in childViewControllers where vc is Databasable {
                var databasable = vc as! Databasable
                databasable.searchService = searchService
            }
            contentPanel?.header.searchService = searchService
        }
    }
    
    /// The source list selection originates in the source list at the far left
    /// and its contents are displayed in a source viewer in the second panel
    
    var sourceListSelection: [DataSource] = [] {
        willSet {
            unloadSourceListSelection()
        }
        didSet {
            log("did change source list selection")
            loadSourceListSelection(sourceListSelection)
        }
    }
    
    /// The source viewer selection originates in the source viewer and may be
    /// a folder, tag, date, file, etc. Its contents are displayed in either the
    /// second or third panel
    
    var sourceViewerSelection: [DataSource] = [] {
        willSet {
            unloadSourceViewerSelection()
        }
        didSet {
            log("did change source viewer selection")
            loadSourceViewerSelection(sourceViewerSelection)
        }
    }
    
    /// ...
    // var URLSelection: [DataSource] = [] { ... }
    
    //
    
    var layout: Layout = .None {
        willSet {
            if layout != newValue {
                saveLayout(layout)
            }
        }
        didSet {
            if layout != oldValue {
                loadLayout(layout)
            }
            leftSourceViewer?.layout = layout
            rightSourceViewer?.layout = layout
        }
    }
    
    var scene: Scene = .None {
        didSet {
            leftSourceViewer?.scene = scene
            rightSourceViewer?.scene = scene
        }
    }
    
    var layoutSetting: [Layout:CGFloat] = [:]
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Acquire child view controllers
        
        layoutController = splitViewItems[1].viewController as! NSSplitViewController
        
        // Using delegates instead of bindings for selection: see SelectionDelegate
        
        sourceListPanel = NSStoryboard(name: "SourceListPanel", bundle: nil).instantiateInitialController() as! SourceListPanel
        replaceSplitViewItem(atIndex: 0, withViewController: sourceListPanel)
        
        sourceListPanel.selectionDelegate = self
        
        // Create the no selection panel and move it into place
        
        noSelectionPanel = NSStoryboard(name: "NoSelectionPanel", bundle: nil).instantiateInitialController() as? NSViewController
        layoutController.replaceSplitViewItem(atIndex: 1, withViewController: noSelectionPanel!)
        
        // Create the content panel and move it into place
        
        contentPanel = NSStoryboard(name: "ContentPanel", bundle: nil).instantiateInitialController() as? ContentPanel
        // layoutController.replaceSplitViewItem(atIndex: 1, withViewController: contentPanel!)
        
        contentPanel!.header.databaseManager = databaseManager
        contentPanel!.header.searchService = searchService
        
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
        
        // TODO: can't use notification center: can, just make sure we're passing the dbm
        // TODO: Set up the initial editor?
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DefaultTab.documentWillSave(_:)), name: DocumentWillSaveNotification, object: nil)
    }
    
    func willClose() {
        sourceListPanel.willClose()
//        inspectorPanel.willClose()
        contentPanel!.willClose()
        
        unbindTitle()
        unbindIcon()
        unbindInspectors()
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
    
    func saveLayout(identifier: Layout) {
        
        let size = layoutController.splitViewItems[0].viewController.view.frame.size
        let position = layoutController.splitView.vertical ? size.width : size.height
        
        layoutSetting[identifier] = position
    }
    
    func loadLayout(identifier: Layout) {
    
        let size = layoutController.splitViewItems[0].viewController.view.frame.size
        let curr = layoutController.splitView.vertical ? size.width : size.height
        let position = layoutSetting[identifier] ?? curr
    
        // Determine if the layout is vertical
    
        var vertical = true
        
        switch identifier {
        case .Compact:
            vertical = true
        case .Expanded:
            vertical = true
        case .Horizontal:
            vertical = false
        default:
            vertical = true
        }
        
        // Adjust vertical
        
        layoutController!.splitView.vertical = vertical
        layoutController!.splitView.adjustSubviews()
        
        // Restore position
        
        layoutController!.splitView.setPosition(position, ofDividerAtIndex: 0)
        
        // Adjust collapsed views for expanded | not layout
        
        switch identifier {
        case .Expanded:
            layoutController!.splitViewItems[0].collapsed = false
            layoutController!.splitViewItems[1].collapsed = true
        case _:
            layoutController!.splitViewItems[0].collapsed = false
            layoutController!.splitViewItems[1].collapsed = false
        }
    }
    
    // MARK: - Source List Selection
    
    func unloadSourceListSelection() {
        unbindTitle()
        unbindIcon()
            
        unbindEditor()
        unbindHeader()
        unbindInspectors()
    }
    
    func loadSourceListSelection(selection: [DataSource]) {
        bindTitle(selection)
        bindIcon(selection)
        
        // should save
        
        // There are files and folders (with selectable editors)
        // Source list selection loads a folder into the first panel
        // If it's a file, save the last non-file layout, load the selection into the second layout panel, and collapse the first
        // That preference (layout/scene) is restored when a folder is selected again
        
        bindEditor(selection)
        bindHeader(selection)
        bindInspectors(selection)
    }
    
    // MARK: - Source Viewer / Editor Selection

    func unloadSourceViewerSelection() {
        unbindTitle()
        unbindIcon()
            
        unbindEditor()
        unbindHeader()
        unbindInspectors()
    }
    
    func loadSourceViewerSelection(selection: [DataSource]) {
        bindTitle(selection)
        bindIcon(selection)
        
        // The source viewer selection always loads into the second panel
        // But whether its embedded into the content panel with a header and inspectors 
        // or loaded directly into the second panel depends on whether it is a file or a folder (with a selectable editor)
        
        bindEditor(selection)
        bindHeader(selection)
        bindInspectors(selection)
    }

    // MARK: - Title and Icon
    
    func bindTitle(selection: [DataSource]) {
        let count = selection.count
        
        switch count {
        case 0:
            title = NSLocalizedString("No Selection", comment: "")
        case 1:
            bind("title", toObject: selection[0], withKeyPath: "title", options: [:])
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
            bind("icon", toObject: selection[0], withKeyPath: "icon", options: [:])
        default:
            icon = nil
        }
    }
    
    func unbindTitle() {
        unbind("title")
    }
    
    func unbindIcon() {
        unbind("icon")
    }
    
    // MARK: - Editor
    
    func bindEditor(selection: [DataSource]) {
        let item = selection[safe: 0]
        
        switch (selection.count, item) {
        case (0, _):
            clearEditor()
            layoutController.replaceSplitViewItem(atIndex: 1, withViewController: noSelectionPanel!)
        case (1, is File):
            loadEditor(item!)
            layoutController.replaceSplitViewItem(atIndex: 1, withViewController: contentPanel!)
        case (1, is Tag): // or the editor more generally is selectable
            loadEditor(item!)
            layoutController.replaceSplitViewItem(atIndex: 1, withViewController: rightSourceViewer as! NSViewController)
        case (1, is Folder):
            clearEditor()
            loadSourceViewer(item!)
            layoutController.replaceSplitViewItem(atIndex: 1, withViewController: noSelectionPanel!)
        case (_,_):
            break
        }
    }
      
    func unbindEditor() {
        guard let rightSourceViewer = rightSourceViewer else {
            return
        }
        rightSourceViewer.source = nil
    }
    
    /// Loads a new file editor iff it has changed,
    /// but always shows the editor if we're in expanded view
    
    func loadEditor(file: DataSource) {
        if layout == .Expanded {
            layoutController.splitViewItems[0].collapsed = true
            layoutController.splitViewItems[1].collapsed = false
            // view.window!.makeFirstResponder(editor!.primaryResponder)
        }
        
        guard rightSourceViewer?.source != file else {
            return
        }
        guard rightSourceViewer == nil || !rightSourceViewer!.dynamicType.filetypes.contains(file.uti) else {
            rightSourceViewer!.source = file
            return
        }
        
        // Acquire a new editor
        
        clearEditor()
        rightSourceViewer = EditorPlugIns.sharedInstance.plugInForFiletype(file.file_extension)
        
        guard rightSourceViewer != nil else {
            log("unable to find editor for file with type \(file.file_extension)")
            clearEditor()
            return
        }
        
        // Prepare the editor
        
        rightSourceViewer!.databaseManager = databaseManager
        rightSourceViewer!.searchService = searchService
        rightSourceViewer!.source = file
        
        rightSourceViewer!.scene = scene
        rightSourceViewer!.layout = layout
        
        // Move the editor into the content panel only if it is not selectable, aka
        // only if it is a file editor
        
        if !(rightSourceViewer is SelectableSourceViewer) {
            contentPanel!.editor = rightSourceViewer
        }
        
        // If we are expanded, collapse the source viewer in favor of the editor
        // Make the editor first responder
        
//        if layout == .Expanded {
//            layoutController.splitViewItems[0].collapsed = true
//            layoutController.splitViewItems[1].collapsed = false
//            view.window!.makeFirstResponder(editor!.primaryResponder)
//        }

        // Establish connections
        
        if let rightSourceViewer = rightSourceViewer as? SelectableSourceViewer {
            rightSourceViewer.selectionDelegate = self
        }

    }
    
    func clearEditor() {
        rightSourceViewer?.willClose()
        rightSourceViewer?.source = nil
        contentPanel!.editor = nil
        rightSourceViewer = nil
    }
    
    /// Loads a new source viewer iff it has changed,
    /// always shows the source if in expanded view
    
    func loadSourceViewer(source: DataSource) {
        if layout == .Expanded {
            layoutController.splitViewItems[0].collapsed = false
            layoutController.splitViewItems[1].collapsed = true
        }
        
        guard leftSourceViewer == nil || !leftSourceViewer!.dynamicType.filetypes.contains(source.uti) else {
            leftSourceViewer!.source = source
            return
        }
        
        // Acquire a new source viewer
        
        leftSourceViewer?.willClose()
        leftSourceViewer = EditorPlugIns.sharedInstance.plugInForFiletype(source.file_extension)
        
        guard leftSourceViewer != nil else {
            log("unable to find editor for file with type \(source.file_extension)")
            clearSource()
            return
        }
        
        // Prepare the source viewer
        
        leftSourceViewer!.databaseManager = databaseManager
        leftSourceViewer!.searchService = searchService
        leftSourceViewer!.source = source
        
        leftSourceViewer!.scene = scene
        leftSourceViewer!.layout = layout
        
        // Move the source viewer into place
        
        guard let layoutController = layoutController else {
            log("layout controller unavailable")
            return
        }
        
        // TODO: maybe would be nice if we didn't need to replace the split view item entirely, as with the editor
        layoutController.replaceSplitViewItem(atIndex: 0, withViewController: leftSourceViewer as! NSViewController)
        
        // Establish connections
        
        if let leftSourceViewer = leftSourceViewer as? SelectableSourceViewer {
            leftSourceViewer.selectionDelegate = self
        }
    }
    
    func clearSource() {
        // unbind("selectedFileObjects")
        leftSourceViewer?.willClose()
        leftSourceViewer = nil
    }
    
    // MARK: - Header
    
    func bindHeader(selection: [DataSource]) {
        let item = selection[safe: 0]
        
        switch (selection.count, item) {
        case (1, is File): loadHeader(item!)
        case (_,_): break
        }
    }
    
    func unbindHeader() {
        contentPanel!.header.file = nil
    }
    
    func loadHeader(file: DataSource) {
        // guard editor != nil && editor!.isFileEditor else {
        guard rightSourceViewer != nil && !(rightSourceViewer is SelectableSourceViewer) else {
            return
        }
        
        // TODO: must be set up when the editor changes as well?
        // Next responder: tab from title to editor
        contentPanel?.header.primaryResponder.nextKeyView = rightSourceViewer?.primaryResponder
        contentPanel?.header.file = file
    }
    
    // MARK: - Inspector
    
    func bindInspectors(selection: [DataSource]) {
        return;
        
        // For multiple selection, the tab manages a metadata inspector view and bindings
        // For single file selection, the file editor has the inspectors and we add metadata
        // For single folder selection, no inspector (or folder metadata?)
        // For no selector: no inspector
        
        let item = selection[safe: 0]
        
        switch (selection.count, item) {
        case (0, _): clearInspector()
        case (1, is File): loadInspector(item!)
        case (1, is Folder): loadInspector(item!)
        case (_,_): loadInspectorForMultipleSelection(selection)
        }
    }
    
    func unbindInspectors() {
        return;
        
        // For single selection, do nothing. The editor handles inspector bindings
        // For multiple selection or inspectors the tab has created, unbind the inspectors
        
        guard let inspectors = inspectors else {
            return
        }

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
    
    func clearInspector() {
        return ;
        
//        inspectorPanel.inspectors = nil
        inspectors = nil
    }
    
    func loadInspector(file: DataSource) {
        return;
        
        guard let rightSourceViewer = rightSourceViewer else {
            clearInspector()
            return
        }
        
        // TODO: only reload inspectors if they are different
        // Don't need to set up bindings or pass files because they are taken care of by the editor
        
        inspectors = rightSourceViewer.inspectors
        
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
        
        // TODO: selected objects is no longer maintained
        
        relatedInspector.bind("selectedObjects", toObject: self, withKeyPath: "selectedObjects", options: [:])
        
        inspectors!.append(metadataInspector)
        inspectors!.append(commentsInspector)
        inspectors!.append(relatedInspector)
        
//        inspectorPanel.inspectors = inspectors
    }
    
    func loadInspectorForMultipleSelection(files: [DataSource]) {
        return;
    }
    
    // MARK: - Search
    
    func performSearch(text: String?, results: BRSearchResults?) {
        guard let library = databaseManager?.librarySource else {
            return
        }
        
        sourceListPanel.selectItem(library)
        rightSourceViewer?.performSearch(text, results: results)
    }
    
}

// MARK: - User Actions

extension DefaultTab {
    
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
            let item = sourceListSelection[safe: 0] where item.uti == DataTypes.Folder.uti {
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
        guard let rightSourceViewer = rightSourceViewer else {
            NSBeep()
            return
        }
        self.view.window?.makeFirstResponder(rightSourceViewer.primaryResponder)
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
        
        // TODO: save sizes for restoration
        
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
    
    @IBAction func toggleDocumentHeader(sender: AnyObject?) {
        contentPanel!.toggleHeader()
    }
    
    // MARK: -
    
    func handleOpenURLNotification(notification: NSNotification) {
        return ;
        
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
                // TODO: re-enable
                // selectedURLObjects = [source]
            }
            rightSourceViewer?.openURL(url)
        case "tags":
            sourceListPanel.selectItem(tags)
            rightSourceViewer?.openURL(url)
        case _:
            log(root)
        }
    }
    
    // MARK: - UI Validation
    
    override func validateMenuItem(menuItem: NSMenuItem) -> Bool {
        switch menuItem.action {
        case #selector(DefaultTab.createNewMarkdownDocument(_:)),
             #selector(DefaultTab.createNewSmartFolder(_:)),
             #selector(DefaultTab.createNewFolder(_:)),
             #selector(DefaultTab.makeFilesAndFoldersFirstResponder(_:)),
             #selector(DefaultTab.makeEditorFirstResponder(_:)),
             #selector(DefaultTab.makeFileInfoFirstResponder(_:)),
             #selector(DefaultTab.changeLayout(_:)):
             return true
        case #selector(DefaultTab.toggleDocumentHeader(_:)):
             menuItem.title = toggleHeaderTitle()
             return sourceViewerSelection[safe: 0] is File
        default:
             return false
        }
    }
    
    func toggleHeaderTitle() -> String {
        return contentPanel!.headerHidden
            ? NSLocalizedString("Show Document Header", comment: "")
            : NSLocalizedString("Hide Document Header", comment: "")
    }

}

// MARK: - Selection Delegate

// Source List Source and File Editor (Collection)

extension DefaultTab: SelectionDelegate {
    func object(object: AnyObject, didChangeSelection selection: [AnyObject]) {
        guard let selection = selection as? [DataSource] else {
            return
        }
        
        switch object {
        case _ as SourceListPanel:
            sourceListSelection = selection
        case _ as SelectableSourceViewer:
            sourceViewerSelection = selection
        default:
            break
        }
    }
}
