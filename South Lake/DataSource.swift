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
    
    // TODO: remove references to icon
    
    class var model_file_extension: NSString { return model_uti as String }
    class var model_mime_type: NSString { return "southlake/source-item" }
    class var model_uti: NSString { return "southlake.source-item" }
    class var model_type: NSString { return "datasource" }
    
    @NSManaged var title: String
    @NSManaged var created_at: NSDate
    @NSManaged var updated_at: NSDate
    @NSManaged var color_labels: [Int]
    @NSManaged var tags: [String]    
    @NSManaged var file_extension: String
    @NSManaged var mime_type: String
    @NSManaged var uti: String
    
    var parents: [DataSource]! = []
    weak var parent: DataSource!
    
    // A source item can in general contain children of any type
    // children <-> children_ids
    
    @NSManaged var children_ids: [String]
    private var _children: [DataSource] = []
    
    var children: [DataSource]! {
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
                child.parents.append(self)
                // child.parent = self
            }
            
            children_ids = theChildrenIds
        }
    }
    
    // The icon is saved as an attachment, but cache it
    
    private var _icon: NSImage?
    
    var icon: NSImage? {
        get {
            guard _icon == nil else {
                return _icon
            }
            
            if  let attachment = attachmentNamed("icon"),
                let content = attachment.content,
                let image = NSImage(data: content) {
                _icon = image
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
                _icon = value
            } else {
                removeAttachmentNamed("icon")
                _icon = nil
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
        
        if type as String? == nil || type == "" {
            type = self.dynamicType.model_type as String
        }
        
        // Avoid nil values for arrays
        
        if color_labels as [Int]? == nil {
            color_labels = []
        }
        
        if tags as [String]? == nil {
            tags = []
        }
        
        if children as [DataSource]? == nil {
            children = []
        }
        
        if parents as [DataSource]? == nil {
            parents = []
        }
    }
    
    override func didLoadFromDocument() {
        super.didLoadFromDocument()
        
        // convert children_ids to children model objects
        
        var theChildren: [DataSource] = []
        
        for id in children_ids {
            let doc = database?.documentWithID(id)
            let child = CBLModel(forDocument: doc!)
            theChildren.append(child as! DataSource)
        }
        
        children = theChildren
    }
    
    override func willSave(changedPropertyNames: Set<NSObject>?) {
        super.willSave(changedPropertyNames)
        
        updated_at = NSDate()
    }
    
    // TODO: a child may belong to more than one parent, then I don't want to delete it
    
    func deleteWithChildren() throws {
        if let children = children {
            for child in children {
                try child.document?.deleteDocument()
            }
        }
        try document?.deleteDocument()
    }
}

// MARK: - NSPasteboardWriting

extension DataSource: NSPasteboardWriting {
    
    @objc func writableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
        let itemTypes = [NSPasteboardTypeString]
        return itemTypes
    }
    
    @objc func writingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardWritingOptions {
        if type == NSPasteboardTypeString {
            return NSPasteboardWritingOptions()
        } else {
            return NSPasteboardWritingOptions()
        }
    }
    
    @objc func pasteboardPropertyListForType(type: String) -> AnyObject? {
        if type == NSPasteboardTypeString {
            return title
        } else {
            return ""
        }
    }
}

// MARK: - NSPasteboardReading

//class DataSourcePasteboardReader: NSObject, NSPasteboardReading {
//    
//    var item: DataSource?
//    
//    static func readableTypesForPasteboard(pasteboard: NSPasteboard) -> [String] {
//        return [kUTTypeFileURL as String]
//    }
//    
//    static func readingOptionsForType(type: String, pasteboard: NSPasteboard) -> NSPasteboardReadingOptions {
//        if UTTypeConformsTo(type, kUTTypeFileURL) {
//            return .AsString
//        } else {
//            return .AsData
//        }
//    }
//    
//    required init?(pasteboardPropertyList propertyList: AnyObject, ofType type: String) {
//        if UTTypeConformsTo(type, kUTTypeFileURL as String) {
//            if  let URL = NSURL(pasteboardPropertyList: propertyList, ofType: type),
//                let filepath = URL.path {
//                
//                // Are we a directory? if so make a folder, otherwise make a document
//                // Eventually we'll recursively do this
//                
//                let fm = NSFileManager()
//                var dir = ObjCBool(false)
//                
//                fm.fileExistsAtPath(URL.path!, isDirectory: &dir)
//                
//                if dir.boolValue {
//                    item = Folder(forNewDocumentInDatabase: DatabaseManager.sharedInstance.database!)
//                    item!.icon_name = "folder_icon"
//                    item!.children = []
//                } else {
//                    item = File(forNewDocumentInDatabase: DatabaseManager.sharedInstance.database!)
//                    item!.icon = NSWorkspace.sharedWorkspace().iconForFile(filepath)
//                    item!.file_extension = URL.fileExtension ?? "unknown"
//                    item!.mime_type = URL.mimeType ?? "unknown"
//                    item!.uti = URL.UTI ?? "unknown"
//                }
//                
//                // Set other metadata
//                
//                item!.title = (URL.lastPathComponent! as NSString).stringByDeletingPathExtension
//                
//                // Save
//                
//                do { try item?.save() } catch {
//                    print(error)
//                    item = nil
//                }
//            }
//        } else {
//        
//        }
//    }
//}
