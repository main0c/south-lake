//
//  ContentPanel.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.

import Cocoa

/// Displays the header and editor views for a file.

class ContentPanel: NSViewController {
    
    // MARK: - Custom Properties
    
    var header: FileHeaderViewController? {
        willSet {
            removeHeaderFromInterface()
        }
        didSet {
            addHeaderToInterface()
        }
    }
    
    var editor: SourceViewer? {
        willSet {
            removeEditorFromInterface()
        }
        didSet {
            addEditorToInterface()
        }
    }
    
    var headerHidden: Bool {
        return header == nil
    }
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.view as! CustomizableView).backgroundColor = UI.Color.SourceViewerBackground
    }
    
    func willClose() {
        header?.willClose()
        editor?.willClose()
    }
    
    // MARK: - Header and Editor Inteface
    
    func removeHeaderFromInterface() {
        guard header != nil else {
            return
        }
        
        header!.removeFromParentViewController()
        header!.view.removeFromSuperview()
    }
    
    func addHeaderToInterface() {
        guard header != nil else {
            return
        }
        
        // Frame
        
        let height = CGFloat(64) // header!.view.frame.size.height
        let width = CGRectGetWidth(view.bounds)
        
        header!.view.translatesAutoresizingMaskIntoConstraints = false
        header!.view.frame = NSMakeRect(0, 0, width, height)
        
        view.addSubview(header!.view)
        addChildViewController(header!)
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": header!.view])
        )
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview(64)]", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": header!.view])
        )
    }

    func removeEditorFromInterface() {
        guard editor != nil else {
            return
        }
        
        editor!.removeFromParentViewController()
        editor!.view.removeFromSuperview()
    }
    
    func addEditorToInterface() {
        guard editor != nil else {
            return
        }
        
        // Frame
        
        let height = CGRectGetHeight(view.bounds) - CGFloat(64)
        let width = CGRectGetWidth(view.bounds)
        
        editor!.view.translatesAutoresizingMaskIntoConstraints = false
        editor!.view.frame = NSMakeRect(0, 0, width, height)
        
        view.addSubview(editor!.view)
        addChildViewController(editor as! NSViewController)
        
        // Layout Constraints
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
        )
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-64-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
        )

    }
}
