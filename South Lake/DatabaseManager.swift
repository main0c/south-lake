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
    
    // Bindable variables that change as the db is re-indexed and their queries
    
    private var _sectionQuery: CBLQuery?
    
    dynamic var tags: [[String:AnyObject]]? {
        get {
            loadTags()
            return _tags
        }
        set {
            _tags = newValue
        }
    }
    
    dynamic var files: [DataSource]? {
        get {
            loadFiles()
            return _files
        }
        set {
            _files = newValue
        }
    }
    
    private var _tags: [[String:AnyObject]]?
    private var _liveTagsQuery: CBLLiveQuery?
    private var _tagsQuery: CBLQuery?
    
    private var _files: [DataSource]?
    private var _liveFilesQuery: CBLLiveQuery?
    private var _filesQuery: CBLQuery?
    
    // MARK: - Initialization
    
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
    
    // MARK: - Queries
    
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
    
    var filesQuery: CBLQuery {
        guard _filesQuery == nil else {
            return _filesQuery!
        }
        
        let view = database!.viewNamed("files")
        view.setMapBlock({ (doc, emit) -> Void in
            if doc["type"] as? String == "file" {
                emit(doc["_id"]!, doc)
            }
        }, version: "1")
        
        _filesQuery = view.createQuery()
        return _filesQuery!
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
    
    // MARK: - Dynamic Queries
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        if object as? NSObject == _liveTagsQuery {
            updateTags(_liveTagsQuery!.rows)
        }
        if object as? NSObject == _liveFilesQuery {
            updateFiles(_liveFilesQuery!.rows)
        }
    }
    
    // MARK: - Tags
    
    func loadTags() {
        guard _liveTagsQuery == nil else {
            return
        }
        
        let query = tagsQuery
        query.groupLevel = 1
        
        _liveTagsQuery = query.asLiveQuery()
        _liveTagsQuery!.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        _liveTagsQuery!.start()
    }
    
    func updateTags(results: CBLQueryEnumerator?) {
        guard let results = results else {
            return
        }
        
        var tags: [[String:AnyObject]] = []
        
        while let row = results.nextRow() {
            let count = row.value as! Int
            let tag = row.key as! String
            
            tags.append([
                "tag": tag,
                "count": count
            ])
        }
        
        self.tags = tags
    }
    
    // MARK: - Files
    
    func loadFiles() {
        guard _liveFilesQuery == nil else {
            return
        }
        
        let query = filesQuery

        _liveFilesQuery = query.asLiveQuery()
        _liveFilesQuery!.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        _liveFilesQuery!.start()
    }
    
    func updateFiles(results: CBLQueryEnumerator?) {
        guard let results = results else {
            return
        }
        
        var files: [File] = []
            
        while let row = results.nextRow() {
            if let document = row.document {
                let file = CBLModel(forDocument: document) as! File
                files.append(file)
            }
        }
        
        self.files = files
    }
}
