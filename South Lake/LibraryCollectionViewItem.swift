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
        // Do view setup here.
        
        backgroundView.backgroundColor = NSColor(white: 1.0, alpha: 1.0)
        backgroundView.borderColor = nil
        backgroundView.borderRadius = 0
        backgroundView.borderWidth = 2

    }
    
    /// Prototypes don't connect outlets so we have to manually
    
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
}

extension NSView {

    // Similar to viewWithTag, finds views with the given identifier.

    func viewWithIdentifier(identifier: String) -> NSView? {
        for subview in self.subviews {
            if subview.identifier == identifier {
                return subview
            } else if subview.subviews.count > 0, let subview: NSView = subview.viewWithIdentifier(identifier) {
                return subview
            }
        }
        return nil
    }
}
