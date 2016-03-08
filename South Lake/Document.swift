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

let DocumentWillSaveNotification = "com.phildow.southlake.documentwillsave"

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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
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
        
        // TODO: refactor
        
        // Save before terminate
        
        NSNotificationCenter.defaultCenter().addObserverForName(NSApplicationWillTerminateNotification, object: nil, queue: nil) { (notification) -> Void in
            self.saveDocument(nil)
        }
        
        // Update search whenever a document is changed in the database (saved)
        
        NSNotificationCenter.defaultCenter().addObserverForName(kCBLDatabaseChangeNotification, object: databaseManager.database, queue: nil) { (notification) -> Void in
            if let changes = notification.userInfo!["changes"] as? [CBLDatabaseChange] {
                for change in changes {
                    NSLog("Document '%@' changed", change.documentID)
                    guard let doc = self.databaseManager.database.documentWithID(change.documentID) else {
                        continue
                    }
                
                    let model = CBLModel(forDocument: doc)
                
                    guard let file = model as? File else {
                        continue
                    }
                    
                    let indexable = BRSimpleIndexable(identifier: file.document!.documentID, data:[
                        kBRSearchFieldNameTitle: file.title,
                        kBRSearchFieldNameValue: file.plain_text
                    ])
                    
                    var error: NSError?
                    self.searchService.addObjectToIndexAndWait(indexable, error: &error)
                    if error != nil {
                        print("unable to index \(file.title)")
                    } else {
                        print("index \(file.title)")
                    }
                }
            }
        }
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
            
            guard let stateURL = self.stateURL(url) else {
                completionHandler(DocumentError.InvalidStateURL as NSError)
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
            
            // Initialize database, search, state
            
            do { try self.initializeDatabase(databaseURL) } catch {
                completionHandler(error as NSError)
            }
            
            do { try self.initializeLucene(luceneURL) } catch {
                completionHandler(error as NSError)
            }
            
            do { try self.initializeState(stateURL) } catch {
                completionHandler(error as NSError)
            }
            
            self.bootstrapDatabase()
            self.bootstrapLucene()
            self.bootstrapState()
            
            // Done
            
            completionHandler(nil)
        }
    }
    
    // Disable document saving: save db, update search, sync, save state
    
    override func saveDocument(sender: AnyObject?) {
        NSNotificationCenter.defaultCenter().postNotificationName(DocumentWillSaveNotification, object: self)
        
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
            
            // Shortcuts section
            
                var children: [DataSource] = []
            
                let doc1 = File(forNewDocumentInDatabase: databaseManager.database)
            
                doc1.title = NSLocalizedString("Welcome to South Lake", comment: "")
                doc1.icon = NSImage(named:"markdown-document-icon")
                doc1.uti = "net.daringfireball.markdown"
                doc1.file_extension = "markdown"
                doc1.mime_type = "text/markdown"
            
                let doc2 = File(forNewDocumentInDatabase: databaseManager.database)
            
                doc2.title = NSLocalizedString("About Markdown", comment: "")
                doc2.icon = NSImage(named:"markdown-document-icon")
                doc2.uti = "net.daringfireball.markdown"
                doc2.file_extension = "markdown"
                doc2.mime_type = "text/markdown"

                // We must have ids before we can store the children
            
                try databaseManager.database.saveAllModels()
            
            let shortcutsSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            shortcutsSection.title = NSLocalizedString("Shortcuts", comment: "Shortcts section title")
            
            shortcutsSection.index = 1
            
                children.append(doc1)
                children.append(doc2)
                shortcutsSection.children = children
            
            // Notebook
            
                var books: [DataSource] = []
            
                let allEntries = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                allEntries.title = NSLocalizedString("Library", comment: "Library folder title")
                allEntries.icon = NSImage(named: "notebook-icon")
                allEntries.file_extension = "southlake-notebook-library"
                allEntries.mime_type = "southlake/x-notebook-library"
                allEntries.uti = "southlake.notebook.library"

            
//                    allEntries.children.append(doc1)
//                    allEntries.children.append(doc2)
            
                let calendar = Folder(forNewDocumentInDatabase: databaseManager.database)
                calendar.title = NSLocalizedString("Calendar", comment: "Library calendar title")
                calendar.icon = NSImage(named: "calendar-icon")
                calendar.file_extension = "southlake-notebook-calendar"
                calendar.mime_type = "southlake/x-notebook-calendar"
                calendar.uti = "southlake.notebook.calendar"
            
                let tags = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                tags.title = NSLocalizedString("Tags", comment: "Tags folder title")
                tags.icon = NSImage(named: "tags-folder-icon")
                tags.file_extension = "southlake-notebook-tags"
                tags.mime_type = "southlake/x-notebook-tags"
                tags.uti = "southlake.notebook.tags"
            
                let trash = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                trash.title = NSLocalizedString("Trash", comment: "Trash folder title")
                trash.icon = NSImage(named: "trash-icon")
                trash.file_extension = "southlake-notebook-trash"
                trash.mime_type = "southlake/x-notebook-trash"
                trash.uti = "southlake.notebook.trash"
            
                try allEntries.save()
                try calendar.save()
                try trash.save()
                try tags.save()
            
            let notebookSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            notebookSection.title = NSLocalizedString("Notebook", comment: "Notebook section title")
            notebookSection.index = 0
            
                books.append(allEntries)
                books.append(calendar)
                books.append(tags)
                books.append(trash)
                
                notebookSection.children = books
            
            // Folders
            
                var folders: [DataSource] = []
            
                let folder1 = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                folder1.title = "Important Folder"
                folder1.icon = NSImage(named: "folder-icon")
            
                let folder2 = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                folder2.title = "Another Folder"
                folder2.icon = NSImage(named: "folder-icon")

                // We must have ids before we can store the children
            
                // try databaseManager.database.saveAllModels()
            
                try folder1.save()
                try folder2.save()
            
//            let foldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
//            
//            foldersSection.title = NSLocalizedString("Folders", comment: "Folders section title")
//            foldersSection.index = 2
//            
//                folders.append(folder1)
//                folders.append(folder2)
//                foldersSection.children = folders
            
            // Smart folders
            
                // var smarts: [DataSource] = []
            
                let smart1 = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
            
                smart1.title = "A Smart Folder"
                smart1.icon = NSImage(named:"smart-folder-icon")
            
                let smart2 = SmartFolder(forNewDocumentInDatabase: databaseManager.database)
            
                smart2.title = "Folders Knows Best"
                smart2.icon = NSImage(named:"smart-folder-icon")

                // We must have ids before we can store the children
            
//                try databaseManager.database.saveAllModels()

                try smart1.save()
                try smart2.save()
            
//            let smartFoldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
//            
//            smartFoldersSection.title = NSLocalizedString("Smart Folders", comment: "Smart folders section title")
//            smartFoldersSection.index = 3
//            
//                smarts.append(smart1)
//                smarts.append(smart2)
//                smartFoldersSection.children = smarts

            let foldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            foldersSection.title = NSLocalizedString("Folders", comment: "Folders section title")
            foldersSection.index = 2
            
                folders.append(folder1)
                folders.append(folder2)
                folders.append(smart1)
                folders.append(smart2)
                foldersSection.children = folders
            
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
    
    func initializeState(url: NSURL) throws {
        try saveState()
    }
    
    func bootstrapState() {
    
    }
    
    func state() -> Dictionary<String,AnyObject> {
        guard windowControllers.count != 0 else {
            return [:]
        }
        
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

