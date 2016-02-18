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
    
    init(url: NSURL) throws {
        super.init()
        
        self.manager = try CBLManager(directory: url.path!, options: nil)
        self.database = try self.manager!.databaseNamed("southlake")
        
        // register model types
        
        let factory = database!.modelFactory
        
        factory?.registerClass(Folder.self, forDocumentType: "folder")
        factory?.registerClass(SmartFolder.self, forDocumentType: "smart_folder")
        factory?.registerClass(Section.self, forDocumentType: "section")
        factory?.registerClass(File.self, forDocumentType: "file")
    }
    
    func sectionsQuery() -> CBLQuery {
        let view = database!.viewNamed("sections")
        view.setMapBlock({ (doc, emit) -> Void in
            if doc["type"] as? String == "section" {
                emit(doc["_id"]!, doc)
            }
        }, version: "1")
        let query = view.createQuery()
        return query
    }
}
