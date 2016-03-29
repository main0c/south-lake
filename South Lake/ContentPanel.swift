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
    
    var editor: DataSourceViewController? {
        willSet {
            removeEditorFromInterface()
        }
        didSet {
            addEditorToInterface()
        }
    }
    
    var headerHidden: Bool = false
    
    var verticalEditorConstraints: [NSLayoutConstraint] = []
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.view as! CustomizableView).backgroundColor = UI.Color.Background.Neutral
            // UI.Color.Background.DataSourceViewController
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
        headerHidden = true
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
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|",
                options: .DirectionLeadingToTrailing,
                metrics: nil,
                views: ["subview": header!.view])
        )
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview(64)]",
                options: .DirectionLeadingToTrailing,
                metrics: nil,
                views: ["subview": header!.view])
        )
        
        headerHidden = false
    }

    func removeEditorFromInterface() {
        guard let editor = editor else {
            return
        }
        
        editor.removeFromParentViewController()
        editor.view.removeFromSuperview()
    }
    
    func addEditorToInterface() {
        guard let editor = editor else {
            return
        }
        
        // Frame
        
        let height = CGRectGetHeight(view.bounds) - CGFloat(64)
        let width = CGRectGetWidth(view.bounds)
        
        editor.view.translatesAutoresizingMaskIntoConstraints = false
        editor.view.frame = NSMakeRect(0, 0, width, height)
        
        view.addSubview(editor.view)
        addChildViewController(editor as! NSViewController)
        
        // Layout Constraints: depends on header visibility
        
        verticalEditorConstraints = editorConstraints(headerHidden)
        
        view.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|",
                options: .DirectionLeadingToTrailing,
                metrics: nil,
                views: ["subview": editor.view])
        )
        view.addConstraints(
            verticalEditorConstraints
        )
    }
    
    // MARK: - Utilities
    
    func toggleHeader() {
        guard let _ = editor else {
            return
        }
        
        if headerHidden {
            addHeaderToInterface()
            view.removeConstraints(verticalEditorConstraints)
            verticalEditorConstraints = editorConstraints(false)
        } else {
            removeHeaderFromInterface()
            view.removeConstraints(verticalEditorConstraints)
            verticalEditorConstraints = editorConstraints(true)
        }
        
        view.addConstraints(verticalEditorConstraints)
    }
    
    func editorConstraints(headerHidden: Bool) -> [NSLayoutConstraint] {
        guard let editor = editor else {
            return []
        }
        
        if headerHidden {
            return NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-0-[subview]-0-|",
                options: .DirectionLeadingToTrailing,
                metrics: nil,
                views: ["subview": editor.view]
            )
        } else {
            return NSLayoutConstraint.constraintsWithVisualFormat(
                "V:|-64-[subview]-0-|",
                options: .DirectionLeadingToTrailing,
                metrics: nil,
                views: ["subview": editor.view]
            )
        }
    }
}
