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
    
    // MARK: - Significant Sections Folders
    
    var notebookSection: Section?
    var shortcutsSection: Section?
    var foldersSection: Section?
    var smartFoldersSection: Section?
    
    var librarySource: DataSource?
    var tagsSource: DataSource?
    var calendarSource: DataSource?
    var trashSource: DataSource?
    
    // MARK: - Bindable DB Properties
    
    dynamic var sections: [Section]? {
        get {
            loadSections()
            return _sections
        }
        set {
            _sections = newValue
        }
    }
    
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
    
    // MARK: - Private Query Properties
    
    private var _sections: [Section]?
    private var _liveSectionsQuery: CBLLiveQuery?
    private var _sectionsQuery: CBLQuery?
    
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
        //factory?.registerClass(SearchResults.self, forDocumentType: "search_results")
        factory?.registerClass(Folder.self, forDocumentType: "folder")
        factory?.registerClass(SmartFolder.self, forDocumentType: "smart_folder")
        factory?.registerClass(File.self, forDocumentType: "file")
    }
    
    // MARK: - Queries
    // TODO: don't need to emit the whole document or even the id?
    
    var sectionsQuery: CBLQuery {
        guard _sectionsQuery == nil else {
            return _sectionsQuery!
        }
        
        let view = database!.viewNamed("sections")
        view.setMapBlock({ (doc, emit) -> Void in
            if doc["type"] as? String == "section" {
                emit(doc["_id"]!, doc)
            }
        }, version: "1")
        
        _sectionsQuery = view.createQuery()
        return _sectionsQuery!
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
        } else if object as? NSObject == _liveFilesQuery {
            updateFiles(_liveFilesQuery!.rows)
        } else if object as? NSObject == _liveSectionsQuery {
            updateSections(_liveSectionsQuery!.rows)
        }
    }
    
    // MARK: - Tags
    
    private func loadTags() {
        guard _liveTagsQuery == nil else {
            return
        }
        
        let query = tagsQuery
        query.groupLevel = 1
        
        _liveTagsQuery = query.asLiveQuery()
        _liveTagsQuery!.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        _liveTagsQuery!.start()
    }
    
    private func updateTags(results: CBLQueryEnumerator?) {
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
    
    private func loadFiles() {
        guard _liveFilesQuery == nil else {
            return
        }
        
        let query = filesQuery

        _liveFilesQuery = query.asLiveQuery()
        _liveFilesQuery!.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        _liveFilesQuery!.start()
    }
    
    private func updateFiles(results: CBLQueryEnumerator?) {
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
    
    // MARK: - Sections
    
    private func loadSections() {
        guard _liveSectionsQuery == nil else {
            return
        }
        
        let query = sectionsQuery
        
        _liveSectionsQuery = query.asLiveQuery()
        _liveSectionsQuery!.addObserver(self, forKeyPath: "rows", options: [], context: nil)
        _liveSectionsQuery!.start()
    }
    
    private func updateSections(results: CBLQueryEnumerator?) {
        guard let results = results else {
            return
        }
        
        var sections: [Section] = []
        
        while let row = results.nextRow() {
            if let document = row.document {
                let section = CBLModel(forDocument: document) as! Section
                sections.append(section)
            }
        }
        
        // Sort the sections in place
        
        sections.sortInPlace({ (x, y) -> Bool in
            return x.index < y.index
        })
        
        self.sections = sections
        
        // Note special folders that are children of the notebook sectiom
        // This may not be the place to do it or the way to do it
        
        cacheSignificantDataSources()
    }
    
    // TODO: failure to cache is a significant error and should be propogated to the user
    
    private func cacheSignificantDataSources() {
        guard librarySource == nil else {
            return
        }
        
        // Sections
        
        guard let notebook = sections?[safe: 0] where notebook.uti == DataTypes.Notebook.uti else {
            print("notebook section not at expected index (0)")
            return
        }
        guard let shortcuts = sections?[safe: 1] where shortcuts.uti == DataTypes.Shortcuts.uti else {
            print("shortcuts not at expected index (1)")
            return
        }
        guard let folders = sections?[safe: 2] where folders.uti == DataTypes.Folders.uti else {
            print("folders not at expected index (2)")
            return
        }
        guard let smartFolders = sections?[safe: 3] where smartFolders.uti == DataTypes.SmartFolders.uti else {
            print("smart folders not at expected index (3)")
            return
        }
        
        // Notebook Data Sources
        
        guard let librarySource = notebook.children[safe: 0] where librarySource.uti == DataTypes.Library.uti else {
            print("library source not at expected index (0)")
            return
        }
        guard let calendarSource = notebook.children[safe: 1] where calendarSource.uti == DataTypes.Calendar.uti  else {
            print("calendar source not at expected index (1)")
            return
        }
        guard let tagsSource = notebook.children[safe: 2] where tagsSource.uti == DataTypes.Tags.uti else {
            print("tags source not at expected index (2)")
            return
        }
        guard let trashSource = notebook.children[safe: 3] where trashSource.uti == DataTypes.Trash.uti else {
            print("trash source not at expected index (3)")
            return
        }
        
        self.notebookSection = notebook
        self.shortcutsSection = shortcuts
        self.foldersSection = folders
        self.smartFoldersSection = smartFolders
        
        self.librarySource = librarySource
        self.calendarSource = calendarSource
        self.tagsSource = tagsSource
        self.trashSource = trashSource
    }
}
