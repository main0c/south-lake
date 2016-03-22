//
//  SourceListPanel.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

struct SourceListDragTypes {
    static var dataSourcePasteboardType = "DataSourcePasteboardType"
}

class SourceListPanel: NSViewController, Databasable {
    @IBOutlet var treeController: NSTreeController!
    @IBOutlet var outlineView: NSOutlineView!
    
    // MARK: - Databasable
    
    var databaseManager: DatabaseManager? {
        didSet {
            bindSections()
        }
    }
    
    var searchService: BRSearchService?
        
    // MARK: - Custom Properties
    
    dynamic var content: [DataSource] = []
    
    dynamic var selectedObjects: [DataSource] = [] {
        didSet {
            selectedObject = selectedObjects[safe:0]
        }
    }
    
    dynamic var selectedObject: DataSource?
    
    private var draggedNodes : [NSTreeNode]?
    
    var selectedIndexPath: NSIndexPath? {
        return treeController.selectionIndexPath
    }
    
    var primaryResponder: NSResponder {
        return outlineView
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Bindings: memory consequences?
        
        bind("selectedObjects", toObject: treeController, withKeyPath: "selectedObjects", options: [:])
        // treeController.bind("content", toObject: self, withKeyPath: "content", options: [:])
        
        // Load data: defer so that the application can bootstrap the database
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.bindSections()
            self.outlineView.expandItem(nil, expandChildren: true)
        }
        
        // Set up outline view
        
        outlineView.setDraggingSourceOperationMask(.Every, forLocal: true)
        outlineView.setDraggingSourceOperationMask(.Every, forLocal: false)
        
        outlineView.registerForDraggedTypes([
            SourceListDragTypes.dataSourcePasteboardType,
            kUTTypeFileURL as String
        ])
        
        outlineView.sizeLastColumnToFit()
    }
    
    func willClose() {
        unbind("selectedObjects")
        unbind("content")
    }
    
    func bindSections() {
        guard let databaseManager = databaseManager else {
            return
        }
        guard unbound("content") else {
            return
        }
        
        bind("content", toObject: databaseManager, withKeyPath: "sections", options: [:])
    }
    
    // MARK: -
    
    override func keyDown(theEvent: NSEvent) {
        switch theEvent.charactersIgnoringModifiers {
        case .Some(String(Character(UnicodeScalar(NSDeleteCharacter)))):
            for item in treeController.selectedNodes {
                deleteItem(item)
            }
        default:
            NSBeep()
        }
    }
    
    func deleteItem(node: NSTreeNode) {
        guard let item = node.representedObject as? DataSource else {
            NSBeep() ; return
        }
        guard !(item is Section) else {
            NSBeep() ; return
        }
        guard item.parents.count != 0 else {
            NSBeep() ; return
        }
        guard let section = sectionOfItem(node) else {
            NSBeep() ; return
        }
        
        // How an item is deleted depends on the section it is being deleted from
        
        // If the item is in the notebook section, do not delete (library, tags, calendar, etc)
        // If the item is in the smartfolder section, do not delete (automatically collected)
        // If the item is in the shortcuts section, remove it from shortcuts
        // If the item is in the folders section, delete it, removing it from all parents
        
        // TODO: confirm deletion
        
        switch section.uti {
        case DataTypes.Notebook.uti, DataTypes.SmartFolders.uti:
            NSBeep()
            
        case DataTypes.Shortcuts.uti:
            section.mutableArrayValueForKey("children").removeObject(item)
            do { try section.save() } catch {
                print(error)
            }
            
        case DataTypes.Folders.uti:
            let alert = NSAlert()
           
            alert.messageText = NSLocalizedString("Delete Items", comment: "")
            alert.informativeText = NSLocalizedString("Deleting a file or folder permanently removes it from your notebook and cannot be undone.", comment: "")
            alert.addButtonWithTitle(NSLocalizedString("Delete", comment: ""))
            alert.addButtonWithTitle(NSLocalizedString("Cancel", comment: ""))
            
            guard alert.runModal() == NSAlertFirstButtonReturn else {
                return
            }
            
            for parent in item.parents {
                parent.mutableArrayValueForKey("children").removeObject(item)
                do { try parent.save() } catch {
                    print(error)
                }
            }
            do { try item.deleteWithChildren() } catch {
                print(error)
            }
            
        case _:
            NSBeep()
        }
    }
    
    /// Walk the parent nodes until we arrived at a section
    func sectionOfItem(node: NSTreeNode?) -> Section? {
        guard let node = node else {
            return nil
        }
        guard let item = node.representedObject as? DataSource else {
            return nil
        }
        
        switch item {
        case let section as Section:
            return section
        case _:
            return sectionOfItem(node.parentNode)
        }
    }
    
    func itemIsDescendant(item: NSTreeNode?, parents: [NSTreeNode]) -> Bool {
        for parent in parents {
            var workingItem = item
            while workingItem != nil {
                if workingItem == parent {
                    return true
                }
                workingItem = workingItem?.parentNode
            }
        }
        return false
    }
    
    func dragIsLocalReorder(info: NSDraggingInfo) -> Bool {
        if info.draggingSource() is NSOutlineView {
            let source = info.draggingSource() as! NSOutlineView
            return source == outlineView
                && draggedNodes != nil
                && info.draggingPasteboard().availableTypeFromArray([SourceListDragTypes.dataSourcePasteboardType]) != nil
        } else {
            return false
        }
    }
    
    // MARK: - IBAction
    
    @IBAction func userDidEndEditingCell(sender: NSTextField) {
        // Update data source title
        
        let row = outlineView.rowForView(sender)
        guard row != -1 else {
            return
        }
            
        if  let node = outlineView.itemAtRow(row) as? NSTreeNode,
            let item = node.representedObject as? DataSource   {
            
            do { try item.save() } catch {
                print(error)
                return
            }
        }
    }
    
    // MARK: - Utilities
    
    func editItemAtIndexPath(indexPath: NSIndexPath) {
        treeController.setSelectionIndexPaths([indexPath])
        outlineView.editColumn(0, row: outlineView.selectedRow, withEvent: nil, select: true)
    }
    
    func selectItemAtIndexPath(indexPath: NSIndexPath) {
        treeController.setSelectionIndexPaths([indexPath])
    }

    func selectItem(item: DataSource) {
        guard let indexPath = treeController.indexPathOfRepresentedObject(item) else {
            print("unable to find index path for item: \(item)")
            return
        }
        selectItemAtIndexPath(indexPath)
    }
    
}

// MARK: - NSOutlineViewDataSource

extension SourceListPanel : NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: AnyObject?, proposedChildIndex index: Int) -> NSDragOperation {
        var operation = NSDragOperation.Generic
        
        // Depends on what we are dragging and where we are dragging it to
        
        if  let item = item as? NSTreeNode,
            let object = item.representedObject as? DataSource {
        
            switch object {
            case _ as File:
                operation = .None
            case _ as Section:
                operation = .Move
                if index == NSOutlineViewDropOnItemIndex {
                    outlineView.setDropItem(item, dropChildIndex: 0)
                }
            case _ as Folder:
                if dragIsLocalReorder(info) {
                    operation = itemIsDescendant(item, parents: draggedNodes!)
                        ? .None
                        : .Move
                } else {
                    operation = .Generic
                }
            default:
                operation = dragIsLocalReorder(info)
                    ? .None
                    : .Generic
            }
        }
        
        return operation
    }
    
    func outlineView(outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: AnyObject?, childIndex index: Int) -> Bool {
        let targetIndex = (index == NSOutlineViewDropOnItemIndex) ? 0 : index
        
        if dragIsLocalReorder(info) {
            return performLocalReorderDrag(info, parent: item as? NSTreeNode, index: targetIndex)
        } else {
            return performExternalDrag(info, parent: item as? NSTreeNode, index: targetIndex)
        }
    }
    
    // Local Reordering Drag Source
    
    func outlineView(outlineView: NSOutlineView, pasteboardWriterForItem item: AnyObject) -> NSPasteboardWriting? {
        let object = item.representedObject
        return object as? NSPasteboardWriting
    }
    
    func outlineView(outlineView: NSOutlineView, draggingSession session: NSDraggingSession, willBeginAtPoint screenPoint: NSPoint, forItems draggedItems: [AnyObject]) {
        session.draggingPasteboard.setData(NSData(), forType: SourceListDragTypes.dataSourcePasteboardType)
        self.draggedNodes = draggedItems as? [NSTreeNode]
    }
    
    func outlineView(outlineView: NSOutlineView, draggingSession session: NSDraggingSession, endedAtPoint screenPoint: NSPoint, operation: NSDragOperation) {
        self.draggedNodes = nil
    }
    
    // Actually Perform Drag
    // TODO: sporadic drag bug still - duplication
    
    func performLocalReorderDrag(info: NSDraggingInfo, parent: NSTreeNode?, index: Int) -> Bool {
        guard let databaseManager = databaseManager else {
            return false
        }
        guard parent != nil else {
            return false
        }
        guard draggedNodes != nil else {
            return false
        }
        
        // For each dragged item, remove it from its parent, add it to the new target
        
        let parentItem = parent?.representedObject as! DataSource
        var targetIndex = index
        
        for draggedNode in draggedNodes! {
            let draggedNodeParent = draggedNode.parentNode!
            
            let draggedItem = draggedNode.representedObject as! DataSource
            let draggedItemParent = draggedNodeParent.representedObject as! DataSource
            
            let indexInParent = draggedItemParent.children.indexOf(draggedItem)!
            
            draggedItemParent.mutableArrayValueForKey("children").removeObjectAtIndex(indexInParent)
            
            // If moving within same parent, adjust target index accordingly
            
            if draggedItemParent == parentItem && targetIndex > indexInParent {
                targetIndex--
            }
            
            parentItem.mutableArrayValueForKey("children").insertObject(draggedItem, atIndex: targetIndex)
            
            targetIndex++
        }
        
        // Save all changes
        
        do { try databaseManager.database?.saveAllModels() } catch {
            print(error)
        }
        
        // Reload the whole thing, expand target
        
        outlineView.reloadItem(nil, reloadChildren: true)
        outlineView.expandItem(parent)
        
        return true
    }
    
    func performExternalDrag(info: NSDraggingInfo, var parent: NSTreeNode?, var index: Int) -> Bool {
        return true
        
        parent = nil
        index = 0
        
//        var targetIndex = index
//        
//        // if parent is nil, retarget to shortcuts section
//        
//        if parent == nil {
//            parent = treeController.arrangedObjects.childNodes!![0] // not really want i want to do
//            index = 0
//        }
//        
//        // build source item and tree node for each dragged item
//        
//        info.enumerateDraggingItemsWithOptions(NSDraggingItemEnumerationOptions(), forView: outlineView, classes: [DataSourcePasteboardReader.self], searchOptions: [NSPasteboardURLReadingFileURLsOnlyKey:true]) { (draggingItem, index, stop) -> Void in
//            
//            let itemReader = draggingItem.item as! DataSourcePasteboardReader
//            guard itemReader.item != nil else {
//                print("unable to produce source item for pboard item")
//                return
//            }
//            
//            let parentItem = parent!.representedObject as! DataSource
//            let item = itemReader.item!
//            
//            parentItem.mutableArrayValueForKey("children").insertObject(item, atIndex: targetIndex)
//            
//            targetIndex++
//        }
//        
//        // Save all changes
//        
//        do { try databaseManager.database?.saveAllModels() } catch {
//            print(error)
//        }
//        
//        // Reload the parent and expand it
//        
//        outlineView.reloadItem(parent, reloadChildren: true)
//        outlineView.expandItem(parent)
//        
//        return true
    }
}

// MARK: - NSOutlineViewDelegate

extension SourceListPanel : NSOutlineViewDelegate {
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let object = item.representedObject
        
        switch object {
        case _ as Section:
            return outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! NSTableCellView
        case _ as Folder,
             _ as File:
            // Can't set NSTableCellView.textField delegate here
            return outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
        default:
            return nil
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        guard item is NSTreeNode else {
            return false
        }
        
        let object = item.representedObject
        return object is Section
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        guard item is NSTreeNode else {
            return false
        }
        
        let object = item.representedObject
        return !(object is Section)
    }
    
//    func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
//        // Never called: because we are view based?
//        guard item is NSTreeNode else {
//            return false
//        }
//        
//        return true
//    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        selectedObjects = outlineView.selectedObjects as! [DataSource]
    }
}

//extension SourceListPanel: NSTextFieldDelegate {
//    func control(control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
//        // Never called
//        return true
//    }
//    
//    func textShouldBeginEditing(textObject: NSText) -> Bool {
//        // Never called
//        return true
//    }
//}
