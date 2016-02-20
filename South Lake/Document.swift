//
//  Document.swift
//  South Lake
//
//  Created by Philip Dow on 2/15/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Document model. Responsible for persisting and restoring document data
//  Primarily that means initializing the database and lucene search service 
//  and maintaining ui state. Keep this class small.

import Cocoa

enum DocumentError: ErrorType {
    case ShouldNotSaveFileWrapper
    case ShouldNotReadFileWrapper
    
    case InvalidDocumentURL
    case InvalidPackageInfoURL
    case InvalidDatabaseURL
    case InvalidLuceneURL
    case InvalidStateURL
    
    case CouldNotInitializeDatabase
    case CouldNotInitializeSearch
    case CouldNotRestoreState
    
    case CouldNotSaveState
}

class Document: NSDocument, Databasable {

    // Couchbase database and search
    
    var databaseManager: DatabaseManager!
    var searchService: BRSearchService!

    // Disable autosaving
    
    override var documentEdited: Bool { return false }
    override var hasUnautosavedChanges: Bool { return false }
    
    override class func autosavesInPlace() -> Bool {
        return false
    }
    
    // MARK: - Initialization

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override func makeWindowControllers() {
        guard windowControllers.count == 0 else {
            return
        }
        
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! DocumentWindowController
        
        windowController.databaseManager = databaseManager
        windowController.searchService = searchService
        
        self.addWindowController(windowController)
    }

    // MARK: - File handling
    
    // Allow the document package to be saved once as an empty wrapper
    // Prevent all later saving, manually manage document package contents

    override func fileWrapperOfType(typeName: String) throws -> NSFileWrapper {
        guard fileURL == nil else {
            print("Document already initialized, don't save")
            throw DocumentError.ShouldNotSaveFileWrapper
        }
        
        return  NSFileWrapper(directoryWithFileWrappers: [:])
    }
    
    override func readFromFileWrapper(fileWrapper: NSFileWrapper, ofType typeName: String) throws {
        throw DocumentError.ShouldNotReadFileWrapper
    }

    override func writeToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: NSURL?) throws {
        try super.writeToURL(url, ofType: typeName, forSaveOperation: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
    }
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        guard let _ = url.path else {
            throw DocumentError.InvalidDocumentURL
        }
        
        guard let luceneURL = self.luceneURL(url) else {
            throw DocumentError.InvalidLuceneURL
        }
        
        guard let databaseURL = self.databaseURL(url) else {
            throw DocumentError.InvalidDatabaseURL
        }
        
        guard let stateURL = self.stateURL(url) else {
            throw DocumentError.InvalidStateURL
        }
        
        // Initialize database and search
            
        try initializeDatabase(databaseURL)
        try initializeLucene(luceneURL)
        
        // Window controller are normally created by NSDocumentController open methods
        // We do it here so that we can restore the state immediately
        
        makeWindowControllers()
        try restoreState(stateURL)
    }
    
    override func saveToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, completionHandler: (NSError?) -> Void) {
        guard fileURL == nil else {
            print("Document already initialized, don't save")
            completionHandler(nil)
            return
        }
        
        super.saveToURL(url, ofType: typeName, forSaveOperation: saveOperation) { (error) -> Void in
            guard let path = url.path else {
                completionHandler(DocumentError.InvalidDocumentURL as NSError)
                return
            }
            
            guard let luceneURL = self.luceneURL(url) else {
                completionHandler(DocumentError.InvalidLuceneURL as NSError)
                return
            }
            
            guard let databaseURL = self.databaseURL(url) else {
                completionHandler(DocumentError.InvalidDatabaseURL as NSError)
                return
            }
            
            guard let packageURL = self.packageURL(url) else {
                completionHandler(DocumentError.InvalidPackageInfoURL as NSError)
                return
            }
            
            // Hide extension: should be unnecessary
            
            do { try NSFileManager().setAttributes([NSFileExtensionHidden: true], ofItemAtPath: path) } catch {
                print(error)
            }
            
            // Package info
            
            do {
                let packageJson = try NSJSONSerialization.dataWithJSONObject(self.packageInfo(), options: .PrettyPrinted)
                packageJson.writeToURL(packageURL, atomically: true)
            } catch {
                completionHandler(error as NSError)
            }
            
            // Initialize database and search
            
            do { try self.initializeDatabase(databaseURL) } catch {
                completionHandler(error as NSError)
            }
            
            do { try self.initializeLucene(luceneURL) } catch {
                completionHandler(error as NSError)
            }
            
            self.bootstrapDatabase()
            self.bootstrapLucene()
            
            // Done
            
            completionHandler(nil)
        }
    }
    
    // Disable document saving: save db, update search, sync, save state
    
    override func saveDocument(sender: AnyObject?) {
        do { try databaseManager.database.saveAllModels() } catch {
            print(error)
        }
        
        do { try saveState() } catch {
            print(error)
        }
    }
    
    // Seriously though, disable autosaving
    
    override func autosaveDocumentWithDelegate(delegate: AnyObject?, didAutosaveSelector: Selector, contextInfo: UnsafeMutablePointer<Void>) {
        return
    }
    
    // MARK: - Database
    
    func databaseURL(documentURL: NSURL) -> NSURL? {
        return documentURL
    }
    
    func initializeDatabase(url: NSURL) throws {
        do { self.databaseManager = try DatabaseManager(url: url) } catch {
            throw DocumentError.CouldNotInitializeDatabase
        }
    }
    
    func bootstrapDatabase() {
        do {
            let query = databaseManager.sectionQuery
            let results = try query.run()
            
            guard results.count == 0 else {
                return
            }
            
            print("bootstraping database")
            
            // Shortcuts section
            
                var children: [DataSource] = []
            
                let doc1 = File(forNewDocumentInDatabase: databaseManager.database)
                doc1.title = "Welcome to Journler"
                doc1.icon = NSImage(named:"markdown-document-icon")
            
                let doc2 = File(forNewDocumentInDatabase: databaseManager.database)
                doc2.title = "Second Document"
                doc2.icon = NSImage(named:"markdown-document-icon")

                // We must have ids before we can store the children
            
                try databaseManager.database.saveAllModels()
            
            let shortcutsSection = Section(forNewDocumentInDatabase: databaseManager.database)
            shortcutsSection.title = "Shortcuts"
            shortcutsSection.index = 0
            
                children.append(doc1)
                children.append(doc2)
                shortcutsSection.children = children
            
            // Folders
            
                var folders: [DataSource] = []
            
                let folder1 = Folder(forNewDocumentInDatabase: databaseManager.database)
                folder1.title = "Important Folder"
                folder1.icon = NSImage(named:"folder-icon")
            
                let folder2 = Folder(forNewDocumentInDatabase: databaseManager.database)
                folder2.title = "Another Folder"
                folder2.icon = NSImage(named:"folder-icon")

                // We must have ids before we can store the children
            
                try databaseManager.database.saveAllModels()
            
            let foldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
            foldersSection.title = "Folders"
            foldersSection.index = 1
            
                folders.append(folder1)
                folders.append(folder2)
                foldersSection.children = folders
            
            // Smart folders
            
                var smarts: [DataSource] = []
            
                let smart1 = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
                smart1.title = "A Smart Folder"
                smart1.icon = NSImage(named:"smart-folder-icon")
            
                let smart2 = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
                smart2.title = "Folders Knows Best"
                smart2.icon = NSImage(named:"smart-folder-icon")

                // We must have ids before we can store the children
            
                try databaseManager.database.saveAllModels()
            
            let smartFoldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
            smartFoldersSection.title = "Smart Folders"
            smartFoldersSection.index = 2
            
                smarts.append(smart1)
                smarts.append(smart2)
                smartFoldersSection.children = smarts
            
            try databaseManager.database.saveAllModels()

        } catch {
            print(error)
        }
    }
    
    // MARK: - Lucene search
    
    func luceneURL(documentURL: NSURL) -> NSURL? {
        guard let documentPath = documentURL.path else {
            return nil
        }
        
        let path = (documentPath as NSString).stringByAppendingPathComponent("lucene")
        return NSURL(fileURLWithPath:path)
    }
    
    func initializeLucene(url: NSURL) throws {
        guard let path = url.path else {
            throw DocumentError.InvalidLuceneURL
        }
        
        self.searchService = CLuceneSearchService(indexPath: path)
            
        if (self.searchService as BRSearchService?) == nil {
            throw DocumentError.CouldNotInitializeSearch
        }
    }
    
    func bootstrapLucene() {
    
    }
    
    // MARK: - Package Info
    // Identifies package version and includes source metadata
    
    func packageURL(documentURL: NSURL) -> NSURL? {
        guard let documentPath = documentURL.path else {
            return nil
        }
        
        let path = (documentPath as NSString).stringByAppendingPathComponent("package.json")
        return NSURL(fileURLWithPath:path)
    }
    
    func packageInfo() -> Dictionary<String, AnyObject> {
        let release = NSBundle.mainBundle().releaseVersionNumber ?? String(0.0)
        let build = NSBundle.mainBundle().buildVersionNumber ?? String(1)
        
        let url = "https://github.com/phildow/south-lake"
        let author = "Philip Dow"
        let name = "South Lake"
        
        return [
            "CFBundleShortVersionString": release,
            "CFBundleVersion": build,
            "version": release,
            "author": author,
            "name": name,
            "url": url
        ]
    }
    
    // MARK: - State
    // Manage document state, primarily user interface state
    
    func stateURL(documentURL: NSURL) -> NSURL? {
        guard let documentPath = documentURL.path else {
            return nil
        }
        
        let path = (documentPath as NSString).stringByAppendingPathComponent("state.plist")
        return NSURL(fileURLWithPath:path)
    }
    
    func state() -> Dictionary<String,AnyObject> {
        return ["WindowController": (windowControllers[0] as! DocumentWindowController).state()]
    }
    
    func saveState() throws {
        guard let stateURL = stateURL(fileURL!) else {
            throw DocumentError.InvalidStateURL
        }
        
        if !(state() as NSDictionary).writeToURL(stateURL, atomically: true) {
            throw DocumentError.CouldNotSaveState
        }
    }
    
    func restoreState(url: NSURL) throws {
        guard let restored = NSDictionary(contentsOfURL: url) as? Dictionary<String, AnyObject> else {
            throw DocumentError.CouldNotRestoreState
        }
        
        if let windowState = restored["WindowController"] as? Dictionary<String,AnyObject> {
            (windowControllers[0] as! DocumentWindowController).restoreState(windowState)
        }
    }
}

