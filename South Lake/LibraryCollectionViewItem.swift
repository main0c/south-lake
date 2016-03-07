//
//  LibraryCollectionViewItem.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class LibraryCollectionViewItem: NSCollectionViewItem {
    @IBOutlet private var backgroundView: NSView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        backgroundView.wantsLayer = true
        backgroundView.layer?.backgroundColor = NSColor(white: 1.0, alpha: 1.0).CGColor
        backgroundView.layer?.borderColor = NSColor(white: 0.8, alpha: 1.0).CGColor
        backgroundView.layer?.borderWidth = 1.0
        
        (backgroundView as! CustomizableView).backgroundColor = NSColor(white: 1.0, alpha: 1.0)
    }
    
}
