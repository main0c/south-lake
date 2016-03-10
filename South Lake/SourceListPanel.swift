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
    
    dynamic var selectedObjects: [DataSource] = []
    dynamic var content: [DataSource] = []
    
    private var draggedNodes : [NSTreeNode]?
    
    var databaseManager: DatabaseManager! {
        didSet {
            loadData()
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
        
        }
    }
    
    var selectedObject: DataSource? {
        return ( selectedObjects.count == 1 ) ? selectedObjects[0] : nil
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Bindings: memory consequences?
        
        self.bind("selectedObjects", toObject: treeController, withKeyPath: "selectedObjects", options: [:])
        treeController.bind("content", toObject: self, withKeyPath: "content", options: [:])
        
        // Load data: defer so that the application can bootstrap the database
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.loadData()
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
        treeController.unbind("content")
        unbind("selectedObjects")
    }
    
    func loadData() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        do {
            let query = databaseManager.sectionQuery
            let results = try query.run()
            var sections: [Section] = []
            
            while let row = results.nextRow() {
                if let document = row.document {
                    let section = CBLModel(forDocument: document) as! Section
                    sections.append(section)
                }
            }
            
            sections.sortInPlace({ (x, y) -> Bool in
                return x.index < y.index
            })
            
            self.content = sections
        } catch {
            print(error)
        }
    }
    
    // MARK: -
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSDeleteCharacter))) {
            for item in treeController.selectedObjects as! [DataSource] {
                deleteItem(item)
            }
        }
    }
    
    // TODO: we have to delete it from this folder and maybe move it to the trash?
    
    func deleteItem(item: DataSource) {
        guard !(item is Section) else {
            NSBeep() ; return
        }
        
        guard item.parents.count != 0 else {
            NSBeep() ; return
        }
        
//        guard item.parent != nil else {
//            NSBeep() ; return
//        }
        
        item.parent.mutableArrayValueForKey("children").removeObject(item)
        
        do {
            try item.parent.save()
            try item.deleteWithChildren()
        } catch {
            print(error)
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
    
    var primaryResponder: NSResponder {
        return outlineView
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
    
    func editItemAtIndexPath(indexPath: NSIndexPath) {
        treeController.setSelectionIndexPaths([indexPath])
        outlineView.editColumn(0, row: outlineView.selectedRow, withEvent: nil, select: true)
    }
    
    func selectItemAtIndexPath(indexPath: NSIndexPath) {
        treeController.setSelectionIndexPaths([indexPath])
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
    
    func outlineView(outlineView: NSOutlineView, shouldEditTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
        guard item is NSTreeNode else {
            return false
        }
        
        return true
    }
    
    func outlineViewSelectionDidChange(notification: NSNotification) {
        selectedObjects = outlineView.selectedObjects as! [DataSource]
    }
}
