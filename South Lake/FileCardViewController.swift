//
//  FileCardViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: The collection view and item might be useful elsewhere, make generally available

import Cocoa

class FileCardViewController: NSViewController, LibraryScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - Databasable

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColors = [UI.Color.FileEditorBackground]
        
        let prototype = storyboard!.instantiateControllerWithIdentifier("FileCardCollectionViewItem") as? FileCardCollectionViewItem
        prototype?.doubleAction = Selector("doubleClick:")
        prototype?.target = self
        
        collectionView.itemPrototype = prototype
    }
    
    func willClose() {
        // OS API bug: 
        // collectionView.itemPrototype must be set to nil for collection view
        // and this view controller to dealloc, but first the content on the
        // array controller must be emptied (see unloadScene())
        collectionView.unbind("content")
        collectionView.unbind("selectionIndexes")
        collectionView.itemPrototype = nil
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
        
        let menuBuilder = MoveToMenuBuilder(databaseManager: databaseManager, action: Selector("executeMoveTo:"), selection: selection)
        
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
        
        print("execute move to \(folder.title)")
    }
    
    // -
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        guard let object = arrayController.selectedObjects[safe: 0] as? DataSource,
              let id = object.id else {
            print("no selected object")
            return
        }
        guard let url = NSURL(string: "southlake://localhost/library/\(id)") else {
            print("unable to construct url for object with id \(id)")
            return
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "source": object,
            "url": url
        ])
    }
    
    override func deleteBackward(sender: AnyObject?) {
        print("deleteBackward")
    }
    
    override func insertNewline(sender: AnyObject?) {
        print("insertNewline")
        doubleClick(sender)
    }
    
    override func quickLookPreviewItems(sender: AnyObject?) {
        print("quickLookPreviewItems")
    }
}

extension FileCardViewController: NSCollectionViewDelegate {
    func collectionView(collectionView: NSCollectionView, canDragItemsAtIndexes indexes: NSIndexSet, withEvent event: NSEvent) -> Bool {
        return true
    }
    
    func collectionView(collectionView: NSCollectionView, writeItemsAtIndexes indexes: NSIndexSet, toPasteboard pasteboard: NSPasteboard) -> Bool {
        
        let items = arrayController.arrangedObjects.objectsAtIndexes(indexes)
        let titles = items.map { $0.title }
        
        pasteboard.declareTypes([UI.Pasteboard.Type.File], owner: nil)
        pasteboard.setPropertyList(titles, forType: NSPasteboardTypeString)
        
        return true
    }
}
