//
//  DatabaseManager.swift
//  South Lake
//
//  Created by Philip Dow on 2/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

/// The Database Manager belongs to a particular document and is made available
/// to the classes that needed it by the view controller hierarchy. Classes that
/// require access to the Database Manager (and Search Service) conform to the 
/// Databasable protocol

class DatabaseManager: NSObject {
    var manager: CBLManager!
    var database: CBLDatabase!
    
    private var _sectionQuery: CBLQuery?
    private var _fileQuery: CBLQuery?
    private var _tagsQuery: CBLQuery?
    
    init(url: NSURL) throws {
        super.init()
        
        self.manager = try CBLManager(directory: url.path!, options: nil)
        self.database = try self.manager!.databaseNamed("southlake")
        
        // register model types
        
        let factory = database!.modelFactory
        
        factory?.registerClass(Section.self, forDocumentType: "section")
        factory?.registerClass(Folder.self, forDocumentType: "folder")
        factory?.registerClass(SmartFolder.self, forDocumentType: "smart_folder")
        factory?.registerClass(File.self, forDocumentType: "file")
    }
    
    // TODO: don't need to emit the whole document or even the id?
    // TODO: factor live query observer code into the dbm?
    
    /// Sections are static, once created in a new document they do not change
    
    var sectionQuery: CBLQuery {
        guard _sectionQuery == nil else {
            return _sectionQuery!
        }
        
        let view = database!.viewNamed("sections")
        view.setMapBlock({ (doc, emit) -> Void in
            if doc["type"] as? String == "section" {
                emit(doc["_id"]!, doc)
            }
        }, version: "1")
        
        _sectionQuery = view.createQuery()
        return _sectionQuery!
    }
    
    /// Files change, a user can create and delete them, maybe we need a live view
    
    var fileQuery: CBLQuery {
        guard _fileQuery == nil else {
            return _fileQuery!
        }
        
        let view = database!.viewNamed("files")
        view.setMapBlock({ (doc, emit) -> Void in
            if doc["type"] as? String == "file" {
                emit(doc["_id"]!, doc)
            }
        }, version: "1")
        
        _fileQuery = view.createQuery()
        return _fileQuery!
    }
    
    /// Tags query, emit and group tags by name, ignoring case?
    
    var tagsQuery: CBLQuery {
        guard _tagsQuery == nil else {
            return _tagsQuery!
        }
        
        let view = database!.viewNamed("tags")
        view.setMapBlock({ (doc, emit) -> Void in
            if  doc["type"] as? String == "file",
                let tags = doc["tags"] as? [String] {
                for tag in tags {
                    emit(tag, 1)
                }
            }
        }, reduceBlock: { (keys, values, rereduce) -> AnyObject in
            return values.count
        }, version: "3")
        
        _tagsQuery = view.createQuery()
        return _tagsQuery!
    }
}
