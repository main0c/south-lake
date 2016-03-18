//
//  TagsCollectionViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: obvious need for factorization, this is not a LibraryScene

import Cocoa

class TagsCollectionViewController: NSViewController, LibraryScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - Databasable

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.backgroundColors = [NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)]
        
        let prototype = storyboard!.instantiateControllerWithIdentifier("tagsCollectionViewItem") as? TagsCollectionViewItem
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
        guard let object = arrayController.selectedObjects[safe: 0] as? [String:AnyObject],
              let tag = object["tag"] as? String,
              let encodedTag = tag.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
            print("no selected object")
            return
        }
        guard let url = NSURL(string: "southlake://localhost/tags/\(encodedTag)") else {
            print("unable to construct url for object with id \(encodedTag)")
            return
        }
        
        // TODO: Track history
        
        print(url)
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "url": url
        ])
    }
    
}
