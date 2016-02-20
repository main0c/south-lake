//
//  Folder.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(Folder)
class Folder: DataSource {
    override class var model_mime_type: NSString { return "private/folder" }
    override class var model_uti: NSString { return "private.folder" }
}

extension Folder {
    var leaf: Bool { return children.count == 0 }
}