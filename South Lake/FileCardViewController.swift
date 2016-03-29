//
//  FileCardViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: The collection view and item might be useful elsewhere, make generally available

import Cocoa

class FileCardViewController: NSViewController, FileCollectionScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - File Collection Scene

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    dynamic var selectedObjects: [DataSource]?
    
    var selectsOnDoubleClick: Bool = false {
        didSet {
            if selectsOnDoubleClick {
                unbind("selectedObjects")
            } else {
                bind("selectedObjects", toObject: arrayController, withKeyPath: "selectedObjects", options: [:])
            }
        }
    }

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Collection View
        
        collectionView.backgroundColors = [UI.Color.Background.SourceViewer]
        
        let prototype = storyboard!.instantiateControllerWithIdentifier("FileCardCollectionViewItem") as? FileCardCollectionViewItem
        prototype?.doubleAction = #selector(FileCardViewController.doubleClick(_:))
        prototype?.target = self
        
        collectionView.itemPrototype = prototype
        
        // Array Controller
        
        bind("selectedObjects", toObject: arrayController, withKeyPath: "selectedObjects", options: [:])
    }
    
    func willClose() {
        unbind("selectedObjects")
        
        // OS API bug:
        // collectionView.itemPrototype must be set to nil for collection view
        // and this view controller to dealloc, but first the content on the
        // array controller must be emptied (see unloadScene())
        collectionView.unbind("content")
        collectionView.unbind("selectionIndexes")
        collectionView.itemPrototype = nil
    }
    
    // MARK: -
    
    func minimize() {
    
    }
    
    func maximize() {
    
    }
    
    // MARK: -
    
    @IBAction func moveTo(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        // TODO: validate so that item is always selected
        guard let collectionItem = collectionView.itemAtIndex(collectionView.selectionIndexes.firstIndex) else {
            NSBeep() ; return
        }
        
        let selection = arrayController.selectedObjects as? [DataSource]
        
        let menuBuilder = MoveToMenuBuilder(databaseManager: databaseManager, action: #selector(FileCardViewController.executeMoveTo(_:)), selection: selection)
        
        guard let menu = menuBuilder.menu() else {
            return
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock {
            menu.popUpMenuPositioningItem(nil, atLocation: NSZeroPoint, inView: collectionItem.view)
        }
    }
    
    @IBAction func executeMoveTo(sender: AnyObject?) {
        guard let sender = sender as? NSMenuItem else {
            return
        }
        guard let folder = sender.representedObject as? Folder else {
            return
        }
        
        log("execute move to \(folder.title)")
    }
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard arrayController.selectedObjects.count > 0 else {
            return
        }
        
        selectedObjects = arrayController.selectedObjects as? [DataSource]
    }
    
    override func deleteBackward(sender: AnyObject?) {
        log("deleteBackward")
    }
    
    override func insertNewline(sender: AnyObject?) {
        log("insertNewline")
        doubleClick(sender)
    }
    
    override func quickLookPreviewItems(sender: AnyObject?) {
        log("quickLookPreviewItems")
    }
}

// MARK: - Collection View Delegate

extension FileCardViewController: NSCollectionViewDelegate {
    func collectionView(collectionView: NSCollectionView, canDragItemsAtIndexes indexes: NSIndexSet, withEvent event: NSEvent) -> Bool {
        return true
    }
    
    func collectionView(collectionView: NSCollectionView, writeItemsAtIndexes indexes: NSIndexSet, toPasteboard pasteboard: NSPasteboard) -> Bool {
        
        let items = arrayController.arrangedObjects.objectsAtIndexes(indexes)
        let titles = items.map { ($0 as! DataSource).title }
        
        pasteboard.declareTypes([UI.Pasteboard.Type.File], owner: nil)
        pasteboard.setPropertyList(titles, forType: NSPasteboardTypeString)
        
        return true
    }
}
