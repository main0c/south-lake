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

class FileHeaderViewController: NSViewController, Databasable {
    @IBOutlet var titleField: NSTextField!
    @IBOutlet var tagsField: NSTokenField!
    @IBOutlet var createdField: NSTextField!
    @IBOutlet var updatedField: NSTextField!

    // MARK: - Databasable
    
    var databaseManager: DatabaseManager? {
        didSet {
            bindTags()
        }
    }
    
    var searchService: BRSearchService?
    
    // MARK: - Custom Properties

    var file: DataSource? {
        willSet {
            unbindMetadata(file)
        }
        didSet {
            bindMetadata(file)
        }
    }
    
    var tokenTracker: NSTokenFieldTokenTracker?
    
    // Keep track of the tags in the db for autocompletion
    // TODO: move these onto the dbm as dynamic variables, e.g. tags, sections, files, etc...
    
    var tagsContent: [[String:AnyObject]]?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        (self.view as! CustomizableView).backgroundColor = NSColor(white:1.0, alpha: 1.0)
        
        tokenTracker = NSTokenFieldTokenTracker(tokenField: tagsField!, delegate: false)
    
        bindTags()
    }
    
    func willClose() {
        unbindMetadata(nil)
        unbind("tagsContent")
    }
    
    deinit {
        print("file header deinit")
    }
    
    // MARK: - Tags Data
    
    func bindTags() {
        guard let databaseManager = databaseManager else {
            return
        }
        
        bind("tagsContent", toObject: databaseManager, withKeyPath: "tags", options: [:])
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
                options:
                    [NSNullPlaceholderBindingOption:NSLocalizedString("Click to change title", comment: "")
                ])
            tagsField.bind("value",
                toObject: selection,
                withKeyPath: "tags",
                options: [
                    NSNullPlaceholderBindingOption:NSLocalizedString("Click to add tags", comment: "")
                ])
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
    }
    
    // MARK: - Utilities
    
    var primaryResponder: NSView {
        return titleField
    }
    
    @IBAction func updateTokens(sender: AnyObject?) {
        guard let file = file else {
            return
        }
        
        file.setValue(tagsField.objectValue, forKey: "tags")
    }
}

extension FileHeaderViewController: NSTokenFieldDelegate {
    
    func tokenField(tokenField: NSTokenField, completionsForSubstring substring: String, indexOfToken tokenIndex: Int, indexOfSelectedItem selectedIndex: UnsafeMutablePointer<Int>) -> [AnyObject]? {
        // Get the tags from the database, predicate filter them beginswith[cd], return the array
        
        guard tagsContent != nil else {
            return nil
        }
        
        let predicate = NSPredicate(format: "tag BEGINSWITH[cd] %@", substring)
        
        return tagsContent!
            .filter { predicate.evaluateWithObject($0) }
            .map { $0["tag"]! }
    }
    
    func control(control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        guard let tokenTracker = tokenTracker else {
            return true
        }
        return tokenTracker.control(control, textShouldBeginEditing: fieldEditor)
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        guard let tokenTracker = tokenTracker else {
            return
        }
        tokenTracker.controlTextDidChange(obj)
    }
}
