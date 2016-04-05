//
//  Tag.swift
//  South Lake
//
//  Created by Philip Dow on 4/4/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

/// A Tag is a File (or a Folder? -- just a DataSource) with its own type. In general treated like a folder
/// Tags are not saved but can be used with a SourceViewer at the interace level.

/// Actually I may not need this at all. Move temporary to data source and then
/// just use the tag type on a file.

/// Don't like this tag business at all. I prefer to just emit the tags, having the model is annoying.
/// But I do want to allow a user to add a tag to the shortcuts

@objc(Tag)
class Tag: DataSource {
    override class var model_mime_type: NSString { return DataTypes.Tag.mime }
    override class var model_uti: NSString { return DataTypes.Tag.uti }
    override class var model_type: NSString { return DataTypes.Tag.model }
 
    var shouldSave: Bool = false
    
    /// Prevent the Tag from saving if it's just being used temporarily at the interface level
    
    override func markNeedsSave() {
        guard shouldSave else {
            return
        }
        super.markNeedsSave()
    }
    
    override func willSave(changedPropertyNames: Set<NSObject>?) {
        super.willSave(changedPropertyNames)
        log("shouldn't happen")
    }
}