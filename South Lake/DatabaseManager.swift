//
//  DatabaseManager.swift
//  South Lake
//
//  Created by Philip Dow on 2/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class DatabaseManager: NSObject {
    var manager: CBLManager!
    var database: CBLDatabase!
    
    private var _sectionQuery: CBLQuery?
    private var _fileQuery: CBLQuery?
    
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
}
