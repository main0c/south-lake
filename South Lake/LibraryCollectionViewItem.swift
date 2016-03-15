//
//  LibraryCollectionViewItem.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class LibraryCollectionViewItem: NSCollectionViewItem {
    @IBOutlet var backgroundView: CustomizableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.backgroundColor = NSColor(white: 1.0, alpha: 1.0)
        backgroundView.borderColor = nil
        backgroundView.borderRadius = 0
        backgroundView.borderWidth = 2

    }
    
    // Prototypes don't connect outlets so we do it manually
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: LibraryCollectionViewItem = super.copyWithZone(zone) as! LibraryCollectionViewItem
        
        copy.backgroundView = copy.view.viewWithIdentifier("background") as! CustomizableView
        copy.backgroundView.backgroundColor = backgroundView.backgroundColor
        copy.backgroundView.borderColor = backgroundView.borderColor
        copy.backgroundView.borderRadius = backgroundView.borderRadius
        copy.backgroundView.borderWidth = backgroundView.borderWidth
        
        return copy
    }
    
    override var selected: Bool {
        didSet {
            guard (backgroundView as NSView?) != nil else {
                return
            }
            backgroundView.borderColor = selected
                ? NSColor(forControlTint: .DefaultControlTint)
                : nil
        }
    }
    
    override func mouseDown(theEvent: NSEvent) {
        if theEvent.clickCount == 2 {
            print("double click")
        } else {
            super.mouseDown(theEvent)
        }
    }
}
