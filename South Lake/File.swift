//
//  File.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(File)
class File: DataSource {
    override class var model_mime_type: NSString { return "private/private" }
    override class var model_uti: NSString { return "private.private" }
    
    // The data is saved as an attachment, but cache it
    // An attachment is available as NSData or a read only file NSURL
    
    private var _data: NSData?
    
    var data: NSData? {
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