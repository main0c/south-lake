//
//  File.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: data continuous bindings - cache data until saved then create attachment?

import Cocoa

@objc(File)
class File: DataSource {
    override class var model_mime_type: NSString { return "private/private" }
    override class var model_uti: NSString { return "private.private" }
    
    @NSManaged var plain_text: String
    
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
            print("file set data")
            
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
        }
    }
}

extension File {
    var leaf: Bool { return true }
}