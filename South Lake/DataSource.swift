//
//  DataSource.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  Abstract super class for data sources, including any container or content

import Cocoa

@objc(DataSource)
class DataSource: CBLModel {
    
    class var model_file_extension: NSString { return model_uti as String }
    class var model_mime_type: NSString { return "private/source-item" }
    class var model_uti: NSString { return "private.source-item" }
    
    @NSManaged var title: String
    @NSManaged var created_at: NSDate
    @NSManaged var updated_at: NSDate
    @NSManaged var color_labels: [Int]
    @NSManaged var tags: [String]
    @NSManaged var icon_name: String
    
    @NSManaged var file_extension: String
    @NSManaged var mime_type: String
    @NSManaged var uti: String
    
    // A source item can in general contain children of any type
    // children <-> children_ids
    
    @NSManaged var children_ids: [String]
    private var _children: [CBLModel] = []
    
    var children: [CBLModel]! {
        get {
            return _children
        }
        set (value) {
            _children = value
            
            var theChildrenIds: [String] = []
            for child in _children {
                let id = child.getValueOfProperty("_id") as? String
                assert(id != nil, "child must have a document id, you must save it first")
                theChildrenIds.append(id!)
            }
            
            children_ids = theChildrenIds
        }
    }
    
    // The icon is saved as an attachment
    
    var icon: NSImage? {
        get {
            if  let attachment = attachmentNamed("icon"),
                let content = attachment.content,
                let image = NSImage(data: content) {
                return image
            } else {
                return nil
            }
        }
        set (value) {
            if  let value = value,
                let rep = value.TIFFRepresentation,
                let bitmap = NSBitmapImageRep(data: rep),
                let data = bitmap.representationUsingType(.NSPNGFileType, properties: [:]) {
                setAttachmentNamed("icon", withContentType: "image/png", content: data)
            } else {
                removeAttachmentNamed("icon")
            }
        }
    }
        
    override func awakeFromInitializer() {
        super.awakeFromInitializer()
        
        // Mark created_at and updated_at on first initialization
        
        if (created_at as NSDate?) == nil {
            let date = NSDate()
            created_at = date
            updated_at = date
        }
        
        // Set default values
        
        if uti as String? == nil || uti == "" {
            uti = self.dynamicType.model_uti as String
        }
        
        if mime_type as String? == nil || mime_type == "" {
            mime_type = self.dynamicType.model_mime_type as String
        }
        
        if file_extension as String? == nil || file_extension == "" {
            file_extension = self.dynamicType.model_file_extension as String
        }
        
        // Avoid nil values for arrays
        
        if color_labels as [Int]? == nil {
            color_labels = []
        }
        
        if tags as [String]? == nil {
            tags = []
        }
        
        if children as [CBLModel]? == nil {
            children = []
        }
    }
    
    override func didLoadFromDocument() {
        super.didLoadFromDocument()
        
        // convert children_ids to children model objects
        
        var theChildren: [CBLModel] = []
        
        for id in children_ids {
            let doc = database?.documentWithID(id)
            let child = CBLModel(forDocument: doc!)
            theChildren.append(child)
        }
        
        children = theChildren
    }
    
    override func willSave(changedPropertyNames: Set<NSObject>?) {
        super.willSave(changedPropertyNames)
        
        updated_at = NSDate()
    }
    
    func deleteDocumentAndChildren() throws {
        if let children = children {
            for child in children {
                try child.document?.deleteDocument()
            }
        }
        try document?.deleteDocument()
    }
}
