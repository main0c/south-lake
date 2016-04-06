//
//  FileListCollectionViewItem.swift
//  South Lake
//
//  Created by Philip Dow on 3/28/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

class FileListCollectionViewItem: NSCollectionViewItem {
    @IBOutlet var backgroundView: CustomizableView!
    
    var target: AnyObject?
    var doubleAction: Selector?
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        backgroundView.backgroundColor = NSColor(white: 1.0, alpha: 1.0)
        backgroundView.borderColor = nil
        backgroundView.borderRadius = 0
        backgroundView.borderWidth = 2
    }
    
    // Prototypes don't connect outlets so we do it manually
    
    override func copyWithZone(zone: NSZone) -> AnyObject {
        let copy: FileListCollectionViewItem = super.copyWithZone(zone) as! FileListCollectionViewItem
        
        copy.backgroundView = copy.view.viewWithIdentifier("background") as! CustomizableView
        copy.backgroundView.backgroundColor = backgroundView.backgroundColor
        copy.backgroundView.borderColor = backgroundView.borderColor
        copy.backgroundView.borderRadius = backgroundView.borderRadius
        copy.backgroundView.borderWidth = backgroundView.borderWidth
        
        copy.doubleAction = doubleAction
        copy.target = target
        
        return copy
    }
    
    // MARK: - First responder observation
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
        guard let window = view.window else {
            return
        }
        
        collectionView.addObserver(self, forKeyPath: "fr", options: [], context: nil)
        
        NSNotificationCenter.defaultCenter().addObserverForName(
            NSWindowDidBecomeKeyNotification,
            object: window,
            queue: nil) {_ in
            self.needsDisplay = true
        }
        NSNotificationCenter.defaultCenter().addObserverForName(
            NSWindowDidResignKeyNotification,
            object: window,
            queue: nil) {_ in
            self.needsDisplay = true
        }
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        
        collectionView.removeObserver(self, forKeyPath: "fr")
        
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSWindowDidBecomeKeyNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSWindowDidResignKeyNotification, object: nil)
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if keyPath == "fr" {
            needsDisplay = true
        } else {
            super.observeValueForKeyPath(keyPath, ofObject: object, change: change, context: context)
        }
    }
    
    // MARK: - State
    
    var isKey: Bool {
        guard let window = view.window else {
            return false
        }
        
        return collectionView.valueForKey("fr") as! Bool
            && window.keyWindow
    }
    
    override var selected: Bool {
        didSet {
            needsDisplay = true
        }
    }
    
    var needsDisplay: Bool = false {
        didSet {
            updateBackgroundColor(selected, firstResponder: isKey)
        }
    }
    
    func updateBackgroundColor(selected: Bool, firstResponder: Bool) {
        guard (backgroundView as NSView?) != nil else {
            return
        }
        
        switch (selected, firstResponder) {
        case (true, true):
            backgroundView.backgroundColor = UI.Color.Selection.KeyView
        case (true, false):
            backgroundView.backgroundColor = UI.Color.Selection.NotKeyView
        case (_,_):
            backgroundView.backgroundColor = NSColor(white: 1.0, alpha: 1.0)
        }
    }
    
    // MARK: - Events
    
    override func mouseDown(theEvent: NSEvent) {
        guard theEvent.clickCount == 2 else {
            super.mouseDown(theEvent)
            return
        }
        guard let target = target as? NSObject,
              let doubleAction = doubleAction else {
            return
        }
        target.performSelector(doubleAction, withObject: self)
    }
    
}