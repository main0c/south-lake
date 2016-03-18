//
//  LibraryCollectionViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: The collection view and item might be useful elsewhere, make generally available

import Cocoa

class LibraryCollectionViewController: NSViewController, LibraryScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - Databasable

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColors = [UI.Color.FileEditorBackground]
        
        let prototype = storyboard!.instantiateControllerWithIdentifier("libraryCollectionViewItem") as? LibraryCollectionViewItem
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
    
}
