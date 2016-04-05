//
//  Tag.swift
//  South Lake
//
//  Created by Philip Dow on 4/4/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

/// A Tag is a File (or a Folder? -- just a DataSource) with its own type. In general treated like a folder
/// Tags are not usually saved but are instead used with a SourceViewer at the interface level
/// A tag may be added to shortcuts and support other drag and interface operations,
/// necessitating its own type.

@objc(Tag)
class Tag: DataSource {
    override class var model_mime_type: NSString { return DataTypes.Tag.mime }
    override class var model_uti: NSString { return DataTypes.Tag.uti }
    override class var model_type: NSString { return DataTypes.Tag.model }
 
    var shouldSave: Bool = false
    
    /// Prevent the Tag from saving if it's just being used temporarily at the interface level
    /// Might want to end up doing this differently
    
    override func markNeedsSave() {
        guard shouldSave else {
            return
        }
        super.markNeedsSave()
    }
    
    override func willSave(changedPropertyNames: Set<NSObject>?) {
        super.willSave(changedPropertyNames)
        log("friends don't let friends normally save tags")
    }
}