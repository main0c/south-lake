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
    @IBOutlet var editorContainer: NSView!
    
    // Title View
    
    @IBOutlet var titleField: NSTextField!
    @IBOutlet var tagsField: NSTokenField!
    @IBOutlet var createdField: NSTextField!
    @IBOutlet var updatedField: NSTextField!
    
    var editor: FileEditor?
    
    dynamic var selectedObjects: [DataSource] = [] {
        willSet {
            unbindEditor(selectedObjects)
            unbindMetadata(selectedObjects)
        }
        didSet {
            bindEditor(selectedObjects)
            bindMetadata(selectedObjects)
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
            
            editorContainer.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
            )
            editorContainer.addConstraints(
                NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": editor!.view])
            )
            
            // Next responder: tab from title to editor
            
            titleField.nextKeyView = editor?.primaryResponder
        // }
         }
        
        // Always pass selection to the editor
        
        editor?.file = file
    }
    
    func clearEditor() {
    
    }
    
    @IBAction func makeEditorFirstResponder(sender: AnyObject?) {
        guard let editor = editor else {
            NSBeep()
            return
        }
        self.view.window?.makeFirstResponder(editor.primaryResponder)
    }
    
    // MARK: - Metadata
    
    func unbindMetadata(selection: [DataSource]) {
        titleField.unbind("value")
        tagsField.unbind("value")
    }
    
    // TODO: could just update a selectedObject property and bind to that
    
    func bindMetadata(selection: [DataSource]) {
        switch selection.count {
        case 0:
            titleField.placeholderString = NSLocalizedString("No Selection", comment: "")
            titleField.stringValue = ""
            
            tagsField.placeholderString = NSLocalizedString("No Selection", comment: "")
            tagsField.stringValue = ""
            
            createdField.placeholderString = NSLocalizedString("No Selection", comment: "")
            createdField.stringValue = ""
            
            updatedField.placeholderString = NSLocalizedString("No Selection", comment: "")
            updatedField.stringValue = ""
        case 1:
            titleField.bind("value", toObject: selectedObjects[0], withKeyPath: "title", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Click to change title", comment: "")])
            tagsField.bind("value", toObject: selectedObjects[0], withKeyPath: "tags", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Click to add tags", comment: "")])
            createdField.bind("value", toObject: selectedObjects[0], withKeyPath: "created_at", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Date Created", comment: "")])
            updatedField.bind("value", toObject: selectedObjects[0], withKeyPath: "updated_at", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Last Updated", comment: "")])
        default:
            titleField.placeholderString = NSLocalizedString("Multiple", comment: "")
            titleField.stringValue = ""
            
            tagsField.placeholderString = NSLocalizedString("Multiple", comment: "")
            tagsField.stringValue = ""
            
            createdField.placeholderString = NSLocalizedString("Multiple", comment: "")
            createdField.stringValue = ""
            
            updatedField.placeholderString = NSLocalizedString("Multiple", comment: "")
            updatedField.stringValue = ""
        }
    }
}
