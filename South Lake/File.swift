//
//  File.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Architecture:
//  These classes all go together, though not necessarily:
//  File, Editor, Importer

//  Markdown is "built in" so it doesn't require an importer, unless you're importing markdown
//  A model class doesn't have to have a corresponding editor, because we can use a generic editor

//  Perhaps some kind of generic Extensions Manager is needed that knows how to
//  load these things given a path, and then can return an object

//  How do I allow 3rd parties to subclass File (or implement a protocol) without
//  including File or the protocol in the bundle?

//  Answer 1: Use a "core" framework - major rearchitecture
//  http://stackoverflow.com/questions/6824213/cocoa-loading-a-bundle-in-which-some-classes-inherit-from-a-custom-framework
//  https://mikeash.com/pyblog/friday-qa-2009-11-06-linking-and-install-names.html

//  Can I weakly link a class instead of a whole framework? Symbols anyway...

//  Answer 2: Use an interpreted language. Totally not an issue when you can guarantee
//  that the interpreter has loaded superclass information before the subclasses

//  Answer 3: Use protocols instead of subclasses. I wonder if protocol symbols are linked into
//  the binary and will cause any conflicts.

//  Architecture: 
//  who is responsible for creating plain text representation?
//  Because at some point we might have plugins for handling model types
//  The editor doesn't know anything about the file, so it can't be the editor
//  That leaves the model object itself, but then it has to be a subclass
//  Template method! -- requires subclasses, don't really want

import Cocoa

@objc(File)
class File: DataSource {
    override class var model_mime_type: NSString { return DataTypes.File.mime }
    override class var model_uti: NSString { return DataTypes.File.uti }
    override class var model_type: NSString { return DataTypes.File.model }
    
    @NSManaged var plain_text: String
    @NSManaged var text_preview: String
    
    // The data is saved as an attachment, but cache it
    // An attachment is available as NSData or a read only file NSURL
    
    private var _data: NSData?
    dynamic var data: NSData? {
        get {
            guard _data == nil else {
                return _data
            }
            
            if  let attachment = attachmentNamed("data"),
                let content = attachment.content {
                _data = content
                return _data
            } else {
                return nil
            }
        }
        set (value) {
            if let value = value {
                // TODO: does removeAttachment not do anything? keeping versions?
                // removeAttachmentNamed("data")
                // do { try save() } catch { print(error) }
                setAttachmentNamed("data", withContentType: mime_type, content: value)
                _data = value
            } else {
                removeAttachmentNamed("data")
                _data = nil
            }
        
            updatePlainText(_data)
            updatePreviewText(plain_text)
        }
    }
    
    func updatePlainText(data: NSData?) {
        if let importer = ImporterPlugIns.sharedInstance.plugInForFiletype(file_extension) {
            plain_text = importer.plainTextRepresentation(data)
        } else {
            print("no importer found for file of type \(file_extension)")
        }
    }
    
    func updatePreviewText(text: String?) {
        guard let text = text else {
            return
        }
        
        let length = text.characters.count
        let index = length < 100 ? length : 100
        
        text_preview = text.substringToIndex(text.startIndex.advancedBy(index))
        print(text_preview)
    }
}

extension File {
    var leaf: Bool { return true }
}