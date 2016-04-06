//
//  FileCardCollectionViewItem.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class FileCardCollectionViewItem: NSCollectionViewItem {
    @IBOutlet var backgroundView: CustomizableView!
    
    var target: AnyObject?
    var doubleAction: Selector?
    
    /// It's possible that viewWillDisappear is called twice when both the layout
    /// and the scene are changed in a tab. Make sure we don't remove the observer
    /// twice.
    
    var observeringFirstResponder = false
    
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
        let copy: FileCardCollectionViewItem = super.copyWithZone(zone) as! FileCardCollectionViewItem
        
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
        observeringFirstResponder = true
        
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
        
        if observeringFirstResponder {
            collectionView.removeObserver(self, forKeyPath: "fr")
            observeringFirstResponder = false
        }
        
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
            backgroundView.borderColor = NSColor(forControlTint: .BlueControlTint) // UI.Color.Selection.KeyView
        case (true, false):
            backgroundView.borderColor = NSColor(forControlTint: .GraphiteControlTint) // UI.Color.Selection.NotKeyView
        case (_,_):
            backgroundView.borderColor = nil
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

