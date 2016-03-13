//
//  ContentViewPanel.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  Contains the editor but also basic metadata info such as the title, etc

import Cocoa

/// Given a FileEditor, knows how to display the editor, knows if it should display a header
/// It does not manage bindings for the editor or header, and it doesn't care what is displayed
/// in the editor or header.

class ContentViewPanel: NSViewController {
    @IBOutlet var viewContainer: NSView!
    @IBOutlet var editorContainer: NSView!
    @IBOutlet var editorContainerTopContraint: NSLayoutConstraint!

    // MARK: - Custom Properties
    
    var header: FileHeaderViewController? {
        willSet {
            removeHeaderFromInterface()
        }
        didSet {
            addHeaderToInterface()
        }
    }
    
    var editor: FileEditor? {
        willSet {
            removeEditorFromInterface()
        }
        didSet {
            addEditorToInterface()
        }
    }
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.layer?.backgroundColor = NSColor(white: 1.0, alpha: 1.0).CGColor
    }
    
    // MARK: - Header and Editor Inteface
    
    func removeHeaderFromInterface() {
        guard header != nil else {
            return
        }
        
        header!.removeFromParentViewController()
        header!.view.removeFromSuperview()
        
        editorContainerTopContraint.constant = 0
    }
    
    func addHeaderToInterface() {
        guard header != nil else {
            return
        }
        
        editorContainerTopContraint.constant = editor!.isFileEditor ? 64 : 0
        
        let height = CGFloat(64) // header!.view.frame.size.height
        let width = viewContainer.bounds.size.width
        
        header!.view.frame = NSMakeRect(0, 0, width, height)
        header!.view.translatesAutoresizingMaskIntoConstraints = false
        
        viewContainer.addSubview(header!.view)
        addChildViewController(header!)
        
        viewContainer.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": header!.view])
        )
        viewContainer.addConstraints(
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
        
        editor!.view.translatesAutoresizingMaskIntoConstraints = false
        editor!.view.frame = editorContainer.bounds
        
        editorContainer.addSubview(editor!.view)
        addChildViewController(editor as! NSViewController)
        
        // Layout Constraints
        
        editorContainer.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
        )
        editorContainer.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
        )

    }
}
