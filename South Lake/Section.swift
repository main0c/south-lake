//
//  Section.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@objc(Section)
class Section: DataSource {
    override class var model_mime_type: NSString { return "southlake/section" }
    override class var model_uti: NSString { return "southlake.section" }
    
    @NSManaged var index: Int
}

extension Section {
    var leaf: Bool { return false }
}
