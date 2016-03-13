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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView.backgroundColors = [NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)]
        
        collectionView.itemPrototype = storyboard!.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
    }
    
}
