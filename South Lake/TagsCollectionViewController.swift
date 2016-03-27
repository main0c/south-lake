//
//  TagsCollectionViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: obvious need for factorization, this is not a FileCollectionScene

import Cocoa

class TagsCollectionViewController: NSViewController, FileCollectionScene {
    @IBOutlet var arrayController: NSArrayController!
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - Databasable

    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    var selectedObjects: [DataSource]?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.backgroundColors = [UI.Color.SourceViewerBackground]
        
        let prototype = storyboard!.instantiateControllerWithIdentifier("tagsListCollectionViewItem") as? TagsCollectionViewItem
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
    
    func minimize() {
    
    }
    
    func maximize() {
    
    }
    
    // MARK: -
    
    @IBAction func doubleClick(sender: AnyObject?) {
        guard let databaseManager = databaseManager else {
            return
        }
        guard let object = arrayController.selectedObjects[safe: 0] as? [String:AnyObject],
              let tag = object["tag"] as? String,
              let encodedTag = tag.stringByAddingPercentEncodingWithAllowedCharacters(NSCharacterSet.URLPathAllowedCharacterSet()) else {
            log("no selected object")
            return
        }
        guard let url = NSURL(string: "southlake://localhost/tags/\(encodedTag)") else {
            log("unable to construct url for object with id \(encodedTag)")
            return
        }
        
        // TODO: Track history
        
        log(url)
        
        NSNotificationCenter.defaultCenter().postNotificationName(OpenURLNotification, object: self, userInfo: [
            "dbm": databaseManager,
            "url": url
        ])
    }
    
    // MARK: - View
    
    var usingIconView: Bool = true
    
    func useIconView() {
        collectionView.maxItemSize = NSMakeSize(227, 33)
        collectionView.maxNumberOfColumns = 0
    }
    
    func useListView() {
        collectionView.maxItemSize = NSMakeSize(0, 33)
        collectionView.maxNumberOfColumns = 1
    }
}
