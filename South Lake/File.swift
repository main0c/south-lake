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
}

extension File {
    var leaf: Bool { return true }
}