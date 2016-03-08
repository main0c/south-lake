//
//  FileHeaderViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  The file header view controller shows metadata about a file, including title,
//  dates, tags, etc... It is the responsibility of a file editor to include the
//  header.

//  TODO: don't like that the editor sets up the header. The header should be the same
//  independent of the editor. So we need some class that handles files like the content
//  view controller that puts the header and the editor together, and some other class
//  that handles other kinds of data sources, generally. I need another refactoring somehwere

import Cocoa

class FileHeaderViewController: NSViewController {
    @IBOutlet var titleField: NSTextField!
    @IBOutlet var tagsField: NSTokenField!
    @IBOutlet var createdField: NSTextField!
    @IBOutlet var updatedField: NSTextField!

    var file: DataSource? {
        willSet {
            unbindMetadata(file)
        }
        didSet {
            bindMetadata(file)
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        (self.view as! CustomizableView).backgroundColor = NSColor(white:1.0, alpha: 1.0)
        // NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
    }
    
    // MARK: - Metadata Bindings
    
    func unbindMetadata(selection: DataSource?) {
        titleField.unbind("value")
        tagsField.unbind("value")
        createdField.unbind("value")
        updatedField.unbind("value")
    }
    
    // TODO: could just update a selectedObject property and bind to that
    
    func bindMetadata(selection: DataSource?) {
        if let selection = selection {
            titleField.bind("value",
                toObject: selection,
                withKeyPath: "title",
                options: [NSNullPlaceholderBindingOption:NSLocalizedString("Click to change title", comment: "")])
            tagsField.bind("value",
                toObject: selection,
                withKeyPath: "tags",
                options: [NSNullPlaceholderBindingOption:NSLocalizedString("Click to add tags", comment: "")])
            createdField.bind("value",
                toObject: selection,
                withKeyPath: "created_at",
                options: [NSNullPlaceholderBindingOption:NSLocalizedString("Date Created", comment: "")])
            updatedField.bind("value",
                toObject: selection,
                withKeyPath: "updated_at",
                options: [NSNullPlaceholderBindingOption:NSLocalizedString("Last Updated", comment: "")])
        } else {
            titleField.placeholderString = NSLocalizedString("No Selection", comment: "")
            titleField.stringValue = ""
            
            tagsField.placeholderString = NSLocalizedString("No Selection", comment: "")
            tagsField.stringValue = ""
            
            createdField.placeholderString = NSLocalizedString("No Selection", comment: "")
            createdField.stringValue = ""
            
            updatedField.placeholderString = NSLocalizedString("No Selection", comment: "")
            updatedField.stringValue = ""
        }
        
//        switch selection.count {
//        case 0:
//            titleField.placeholderString = NSLocalizedString("No Selection", comment: "")
//            titleField.stringValue = ""
//            
//            tagsField.placeholderString = NSLocalizedString("No Selection", comment: "")
//            tagsField.stringValue = ""
//            
//            createdField.placeholderString = NSLocalizedString("No Selection", comment: "")
//            createdField.stringValue = ""
//            
//            updatedField.placeholderString = NSLocalizedString("No Selection", comment: "")
//            updatedField.stringValue = ""
//        case 1:
//            titleField.bind("value", toObject: selectedObjects[0], withKeyPath: "title", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Click to change title", comment: "")])
//            tagsField.bind("value", toObject: selectedObjects[0], withKeyPath: "tags", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Click to add tags", comment: "")])
//            createdField.bind("value", toObject: selectedObjects[0], withKeyPath: "created_at", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Date Created", comment: "")])
//            updatedField.bind("value", toObject: selectedObjects[0], withKeyPath: "updated_at", options: [NSNullPlaceholderBindingOption:NSLocalizedString("Last Updated", comment: "")])
//        default:
//            titleField.placeholderString = NSLocalizedString("Multiple", comment: "")
//            titleField.stringValue = ""
//            
//            tagsField.placeholderString = NSLocalizedString("Multiple", comment: "")
//            tagsField.stringValue = ""
//            
//            createdField.placeholderString = NSLocalizedString("Multiple", comment: "")
//            createdField.stringValue = ""
//            
//            updatedField.placeholderString = NSLocalizedString("Multiple", comment: "")
//            updatedField.stringValue = ""
//        }
    }
    
    // MARK: - Utilities
    
    var primaryResponder: NSView {
        return titleField
    }
}
