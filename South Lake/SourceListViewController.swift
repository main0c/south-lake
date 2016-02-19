//
//  SourceListViewController.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

struct SourceListDragTypes {
    static var sourceItemPasteboardType = "SourceItemPasteboardType"
}

class SourceListViewController: NSViewController, Databasable {
    @IBOutlet var outlineView: NSOutlineView!

    var root: NSTreeNode = NSTreeNode(representedObject: nil)
    private var draggedNodes : [NSTreeNode]?
    
    dynamic var selectedObjects: [DataSource] = []
    
    var databaseManager: DatabaseManager! {
        didSet {
            loadData()
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
        
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Load data: defer so that the application can bootstrap the database
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.loadData()
        }
        
        // Set up outline view
        
        outlineView.setDraggingSourceOperationMask(.Every, forLocal: true)
        outlineView.setDraggingSourceOperationMask(.Every, forLocal: false)
        
        outlineView.registerForDraggedTypes([
            SourceListDragTypes.sourceItemPasteboardType,
            kUTTypeFileURL as String
        ])
        
        outlineView.sizeLastColumnToFit()
    }
    
    func loadData() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        root = NSTreeNode(representedObject: nil)
        
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
            
            // Build the tree: see SourceItem extension at bottom
            
            for section in sections {
                let node = section.treeNode()
                root.mutableChildNodes.addObject(node)
            }
            
            outlineView.reloadItem(nil)
            outlineView.expandItem(nil, expandChildren: true)
            
        } catch {
            print(error)
        }
    }
    
    override func keyDown(theEvent: NSEvent) {
        if theEvent.charactersIgnoringModifiers == String(Character(UnicodeScalar(NSDeleteCharacter))) {
            for row in outlineView.selectedRowIndexes.reverse() {
                if let node = outlineView.itemAtRow(row) as? NSTreeNode {
                    outlineView.deselectRow(row)
                    deleteItem(node)
                } else {
                    NSBeep()
                }
            }
        }
    }
    
    func deleteItem(node: NSTreeNode) {
        let item = node.representedObject as! DataSource
        
        guard !(item is Section) else {
            return
        }
        
        // Remove the item from the parent, every item has a parent
        
        if  let parentNode = node.parentNode,
            let parent = parentNode.representedObject as? DataSource {
            let index = parent.children.indexOf(item)!
            
            parentNode.mutableChildNodes.removeObjectAtIndex(index)
            parent.children.removeAtIndex(index)
            
            do { try parent.save() } catch {
                print(error)
                return
            }
            
            do { try item.deleteDocumentAndChildren() } catch {
                print(error)
                return
            }
            
            outlineView.reloadItem(parentNode, reloadChildren: true)
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
                && info.draggingPasteboard().availableTypeFromArray([SourceListDragTypes.sourceItemPasteboardType]) != nil
        } else {
            return false
        }
    }
    
    // MARK: - IBAction: Refactor
    
    @IBAction func createNewFolder(sender: AnyObject) {
        // Create an untitled folder
        
        let folder = Folder(forNewDocumentInDatabase: databaseManager.database)
        folder.title = NSLocalizedString("Untitled", comment: "Name for new untitled folder")
        folder.icon_name = "folder-icon"
        
        do { try folder.save() } catch {
            print(error)
            return
        }
        
        // Create a node representing that folder
        
        let folderNode = folder.treeNode()
        
        // Either add the folder to the Folders section or the selected folder
        
        var parent: DataSource!
        
        let row = outlineView.selectedRow
        var node = outlineView.itemAtRow(row) as? NSTreeNode
        
        if  let node = node,
            let item = node.representedObject as? DataSource where (item is Folder && !(item is SmartFolder)) {
            parent = item
        } else {
            parent = root.childNodes![1].representedObject as! DataSource
            node = nil
        }
        
        // Update the parent
        
        parent.children.append(folder)
        
        do { try parent.save() } catch {
            print(error)
            return
        }
        
        // Update the node representation
        
        if (node == nil) {
            node = root.childNodes![1]
        }
        
        node!.mutableChildNodes.addObject(folderNode)
        
        // Refresh the interface and select/edit the item
        
        outlineView.reloadItem(node, reloadChildren: true)
        outlineView.expandItem(node)
        
        outlineView.selectRowIndexes(NSIndexSet(index: outlineView.rowForItem(folderNode)), byExtendingSelection: false)
        outlineView.editColumn(0, row: outlineView.rowForItem(folderNode), withEvent: nil, select: true)
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject) {
        // Create an untitled smart folder
        
        let folder = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
        folder.title = NSLocalizedString("Untitled", comment: "Name for new untitled smart folder")
        folder.icon_name = "smart-folder-icon"
        
        do { try folder.save() } catch {
            print(error)
            return
        }
        
        // Create a node representing that folder
        
        let folderNode = folder.treeNode()
        
        // Add the folder to the Smart Folders section
        
        let parent = root.childNodes![2].representedObject as! DataSource
        parent.children.append(folder)
        
        do { try parent.save() } catch {
            print(error)
            return
        }
        
        // Update the node representation
        
        let node = root.childNodes![2]
        node.mutableChildNodes.addObject(folderNode)
        
        // Refresh the interface and select/edit the item
        
        outlineView.reloadItem(node, reloadChildren: true)
        outlineView.expandItem(node)
        
        outlineView.selectRowIndexes(NSIndexSet(index: outlineView.rowForItem(folderNode)), byExtendingSelection: false)
        outlineView.editColumn(0, row: outlineView.rowForItem(folderNode), withEvent: nil, select: true)
    }
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject) {
        // Create an untitled markdown document
        
        let document = File(forNewDocumentInDatabase: databaseManager.database)
        document.title = NSLocalizedString("Untitled", comment: "Name for new untitled document")
        document.icon_name = "markdown-document-icon"
        
        do { try document.save() } catch {
            print(error)
            return
        }
        
        // Create a node representing that folder
        
        let documentNode = document.treeNode()
        
        // Either add the document to the Shortcuts section or the selected folder
        
        var parent: DataSource!
        
        let row = outlineView.selectedRow
        var node = outlineView.itemAtRow(row) as? NSTreeNode
        
        if  let node = node,
            let item = node.representedObject as? DataSource where item is Folder {
            parent = item
            print("folder selected: %@", item)
        } else {
            parent = root.childNodes![0].representedObject as! DataSource
            node = nil
        }
        
        // Update the parent
        
        parent.children.append(document)
        
        do { try parent.save() } catch {
            print(error)
            return
        }
        
        // Update the node representation
        
        if (node == nil) {
            node = root.childNodes![0]
        }
        
        node!.mutableChildNodes.addObject(documentNode)
        
        // Refresh the interface and select/edit the item
        
        outlineView.reloadItem(node, reloadChildren: true)
        outlineView.expandItem(node)
        
        outlineView.selectRowIndexes(NSIndexSet(index: outlineView.rowForItem(documentNode)), byExtendingSelection: false)
        outlineView.editColumn(0, row: outlineView.rowForItem(documentNode), withEvent: nil, select: true)
    }
    
    @IBAction func userDidEndEditingCell(sender: NSTextField) {
        // Update data source title
        
        let row = outlineView.rowForView(sender)
        guard row != -1 else {
            return
        }
            
        if  let node = outlineView.itemAtRow(row) as? NSTreeNode,
            let item = node.representedObject as? DataSource   {
            
            item.title = sender.stringValue
            
            do { try item.save() } catch {
                print(error)
                return
            }
        }
    }
}

// MARK: - NSOutlineViewDataSource

extension SourceListViewController : NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        if let node = item as? NSTreeNode {
            if let children = node.childNodes {
                return children.count
            } else {
                return 0
            }
        } else {
            if let children = root.childNodes {
                return children.count
            } else {
                return 0
            }
        }
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        if let node = item as? NSTreeNode {
            return node.childNodes![index]
        } else {
            return root.childNodes![index]
        }
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        let object = item.representedObject
        switch object {
        case let section as Section:
            return section.children.count != 0
        case let folder as Folder:
            return folder.children.count != 0
        default:
            return false
        }
    }
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        let object = item.representedObject
        switch object {
        case let section as Section:
            let view = outlineView.makeViewWithIdentifier("HeaderCell", owner: self) as! NSTableCellView
            view.textField?.stringValue = section.title
            return view
        case let folder as Folder:
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
            view.textField?.stringValue = folder.title
            if let icon = folder.icon {
                view.imageView?.image = icon
            } else {
                view.imageView?.image = NSImage(named: folder.icon_name)
            }
            return view
        case let file as File:
            let view = outlineView.makeViewWithIdentifier("DataCell", owner: self) as! NSTableCellView
            view.textField?.stringValue = file.title
            if let icon = file.icon {
                view.imageView?.image = icon
            } else {
                view.imageView?.image = NSImage(named: file.icon_name)
            }
            return view
        default:
            return nil
        }
    }
}

// MARK: - NSOutlineViewDelegate

extension SourceListViewController : NSOutlineViewDelegate {
    
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

// MARK: - DataSource TreeNode Extension

extension DataSource {
    func treeNode() -> NSTreeNode {
        let node = NSTreeNode(representedObject: self)
        if children != nil {
            for child in children as! [DataSource] {
                let childNode = child.treeNode()
                node.mutableChildNodes.addObject(childNode)
            }
        }
        return node
    }
}
