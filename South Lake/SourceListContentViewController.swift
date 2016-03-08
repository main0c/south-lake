//
//  SourceListContentViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  Contains the editor but also basic metadata info such as the title, etc

//  TODO: factor title view
//  TOOD: factor: it doesn't need to be associated with a source list, usable anywhere

import Cocoa

class SourceListContentViewController: NSViewController, Databasable {
    @IBOutlet var viewContainer: NSView!
    @IBOutlet var editorContainer: NSView!
    @IBOutlet var editorContainerTopContraint: NSLayoutConstraint!
    
    var header: FileHeaderViewController?
    var editor: FileEditor?
    
    dynamic var selectedObjects: [DataSource] = [] {
        willSet {
            unbindEditor(selectedObjects)
        }
        didSet {
            bindEditor(selectedObjects)
        }
    }
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    var selectedObject: DataSource? {
        return ( selectedObjects.count == 1 ) ? selectedObjects[0] : nil
    }
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        self.view.layer?.backgroundColor = NSColor(white: 1.0, alpha: 1.0).CGColor
    }
    
    func willClose() {
        unbindEditor(selectedObjects)
    }
    
    // MARK: - Editor
    
    func bindEditor(selection: [DataSource]) {
        let item = selectedObject
        
        switch (selection.count, item) {
        case (0, _): clearEditor()
        case (1, is File): loadEditor(item!)
        case (1, is Folder): loadEditor(item!)
        case (_,_): break
        }
    }
      
    func unbindEditor(selection: [DataSource]) {
        guard let editor = editor, let file = selectedObject
        where file is File || file is Folder else {
            return
        }
        editor.file = nil
    }
    
    // MARK: - Editor
    
    func loadEditor(file: DataSource) {
        // Load editor if editor has changed
        
        if editor == nil || !editor!.dynamicType.filetypes.contains(file.uti) {
        // if !(editor is MarkdownEditor) {
            
            // TODO: guard this, raise exception -- what?
            
            guard let editorExtension = EditorPlugIns.sharedInstance.plugInForFiletype(file.file_extension) else {
                print("unable to find editor for file with type \(file.file_extension)")
                return
            }
            
            // Remove the previous editor
            
            editor?.view.removeFromSuperview()
            editor?.removeFromParentViewController()
            
            // Note and prepare the loaded editor
            
            editor = editorExtension
            
            editor!.databaseManager = databaseManager
            editor!.searchService = searchService
            
            // Add the current editor
            
            editorContainer.addSubview(editor!.view)
            editor!.view.frame = editorContainer.bounds
            editor!.view.translatesAutoresizingMaskIntoConstraints = false
            addChildViewController(editor as! NSViewController)
            
            // Layout Constraints
            
            editorContainerTopContraint.constant = editor!.isFileEditor
                ? 64
                : 0
            
            editorContainer.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
            )
            editorContainer.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
            )
            
            // TODO: tab from title to editor
            // Next responder: tab from title to editor
            
//            titleField.nextKeyView = editor?.primaryResponder
        // }
         }
        
        // Always pass selection to the editor
        
        editor?.file = file
        
        // Load header if needed
        
        // If the editor is a file editor, add the file info header
        // Mixture of hardcoded 64 height and file header height
        // Does this belong here?
        
        if editor!.isFileEditor {
            if ( header == nil ) {
                header = NSStoryboard(name: "FileHeader", bundle: nil).instantiateInitialController() as? FileHeaderViewController
                
                let height = CGFloat(64) // header!.view.frame.size.height
                let width = viewContainer.bounds.size.width
                
                header!.view.frame = NSMakeRect(0, 0, width, height)
                header!.view.translatesAutoresizingMaskIntoConstraints = false
                viewContainer.addSubview(header!.view)
                
                viewContainer.addConstraints(
                    NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": header!.view])
                )
                viewContainer.addConstraints(
                    NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview(64)]", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": header!.view])
                )
                
                // Next responder: tab from title to editor
                header?.primaryResponder.nextKeyView = editor?.primaryResponder
            }
            
            header!.file = file
            
        } else {
            if header != nil {
                header!.view.removeFromSuperview()
                header!.file = nil
                header = nil
            }
        }
    }
    
    func clearEditor() {
    
    }
    
    func clearHeader() {
    
    }
    
    @IBAction func makeEditorFirstResponder(sender: AnyObject?) {
        guard let editor = editor else {
            NSBeep()
            return
        }
        self.view.window?.makeFirstResponder(editor.primaryResponder)
    }
    
}
