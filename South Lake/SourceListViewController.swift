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
            let sectionQuery = databaseManager.sectionsQuery()
            let results = try sectionQuery.run()
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
    
    // MARK: - IBAction
    
    @IBAction func createNewFolder(sender: AnyObject) {
        // Create an untitled folder
    }
    
    @IBAction func createNewSmartFolder(sender: AnyObject) {
        // Create an untitled smart folder
    }
    
    @IBAction func createNewMarkdownDocument(sender: AnyObject) {
        // Create an untitled document
    }
    
    @IBAction func userDidEndEditingCell(sender: NSTextField) {
        // Update data source title
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
