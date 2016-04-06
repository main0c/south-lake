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
    
    /// Controls whether the tag should be saved or not, defaults to false
    
    var shouldSave: Bool = false
    
    /// Count is a temporary variable used when emitted tags are collected and
    /// represented by a Tag type
    
    dynamic var count: Int = 0
    
    // TODO: temporary for transition to Tag type from dictionary
    
    dynamic var tag: String { return title }
    
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