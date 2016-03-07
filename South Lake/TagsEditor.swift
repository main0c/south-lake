//
//  TagsEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class TagsEditor: NSViewController, FileEditor {
    @IBOutlet var collectionView: NSCollectionView!

    static var filetypes: [String] { return ["southlake.notebook.tags"] }
    static var storyboard: String { return "TagsEditor" }
    
    dynamic var file: DataSource? {
        willSet {
        
        }
        didSet {
        
        }
    }
    
    var primaryResponder: NSView {
        return view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        collectionView.itemPrototype = storyboard!.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
    }
    
}
