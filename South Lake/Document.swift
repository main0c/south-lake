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
import Quartz // temporary

let DocumentWillSaveNotification = "com.phildow.southlake.documentwillsave"
let OpenURLNotification = "com.phildow.southlake.openurl"

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

/// The document conforms to non-optional Databasable. Other objects should too.

class Document: NSDocument {

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
                    
                    let indexable = BRSimpleIndexable(identifier: change.documentID, data:[
                        kBRSearchFieldNameTitle: file.title,
                        kBRSearchFieldNameValue: file.plain_text,
                        String("q"): file.tags
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
            let query = databaseManager.sectionsQuery
            let results = try query.run()
            
            guard results.count == 0 else {
                return
            }
            
            // Notebook
            
                var books: [DataSource] = []
            
                let allEntries = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                allEntries.title = NSLocalizedString("Library", comment: "Library folder title")
                allEntries.icon = NSImage(named: "notebook-icon")
                allEntries.file_extension = DataTypes.Library.ext
                allEntries.mime_type = DataTypes.Library.mime
                allEntries.uti = DataTypes.Library.uti

                    // Children don't need to be explicitly added to the library
            
                let calendar = Folder(forNewDocumentInDatabase: databaseManager.database)
                calendar.title = NSLocalizedString("Calendar", comment: "Library calendar title")
                calendar.icon = NSImage(named: "calendar-icon")
                calendar.file_extension = DataTypes.Calendar.ext
                calendar.mime_type = DataTypes.Calendar.mime
                calendar.uti = DataTypes.Calendar.uti
            
                let tags = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                tags.title = NSLocalizedString("Tags", comment: "Tags folder title")
                tags.icon = NSImage(named: "tags-folder-icon")
                tags.file_extension = DataTypes.Tags.ext
                tags.mime_type = DataTypes.Tags.mime
                tags.uti = DataTypes.Tags.uti
            
//                let trash = Folder(forNewDocumentInDatabase: databaseManager.database)
//            
//                trash.title = NSLocalizedString("Trash", comment: "Trash folder title")
//                trash.icon = NSImage(named: "trash-icon")
//                trash.file_extension = DataTypes.Trash.ext
//                trash.mime_type = DataTypes.Trash.mime
//                trash.uti = DataTypes.Trash.uti
            
                try allEntries.save()
                try calendar.save()
                try tags.save()
//                try trash.save()
            
            let notebookSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            notebookSection.title = NSLocalizedString("Notebook", comment: "Notebook section title")
            notebookSection.index = 0
            notebookSection.file_extension = DataTypes.Notebook.ext
            notebookSection.mime_type = DataTypes.Notebook.mime
            notebookSection.uti = DataTypes.Notebook.uti
            
                books.append(allEntries)
                books.append(calendar)
                books.append(tags)
//                books.append(trash)
            
                notebookSection.children = books
            
            // Shortcuts section
            
                var children: [DataSource] = []
            
                let doc1 = File(forNewDocumentInDatabase: databaseManager.database)
            
                doc1.title = NSLocalizedString("Welcome to South Lake", comment: "")
                doc1.icon = NSImage(named:"markdown-document-icon")
                doc1.file_extension = DataTypes.Markdown.ext
                doc1.mime_type = DataTypes.Markdown.mime
                doc1.uti = DataTypes.Markdown.uti
            
                let doc2 = File(forNewDocumentInDatabase: databaseManager.database)
            
                doc2.title = NSLocalizedString("About Markdown", comment: "")
                doc2.icon = NSImage(named:"markdown-document-icon")
                doc2.file_extension = DataTypes.Markdown.ext
                doc2.mime_type = DataTypes.Markdown.mime
                doc2.uti = DataTypes.Markdown.uti

                // PDF Test

                let URL = NSBundle.mainBundle().URLForResource("As We May Think - The Atlantic", withExtension: "pdf")!

                let doc3 = File(forNewDocumentInDatabase: databaseManager.database)
                doc3.title = NSLocalizedString("As We May Think", comment: "")
                doc3.icon = NSWorkspace.sharedWorkspace().iconForFile(URL.path!)
                doc3.file_extension = URL.fileExtension ?? "unknown"
                doc3.mime_type = URL.mimeType ?? "unknown"
                doc3.uti = URL.UTI ?? "unknown"
                doc3.data = PDFDocument(URL: URL).dataRepresentation()

                // We must have ids before we can store the children
            
                try doc1.save()
                try doc2.save()
                try doc3.save()
            
            let shortcutsSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            shortcutsSection.title = NSLocalizedString("Shortcuts", comment: "Shortcts section title")
            shortcutsSection.index = 1
            shortcutsSection.file_extension = DataTypes.Shortcuts.ext
            shortcutsSection.mime_type = DataTypes.Shortcuts.mime
            shortcutsSection.uti = DataTypes.Shortcuts.uti
            
                children.append(doc1)
                children.append(doc2)
                children.append(doc3) // pdf
                shortcutsSection.children = children
            
            // Folders
            
                var folders: [DataSource] = []
            
                let folder1 = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                folder1.title = "Important Folder"
                folder1.icon = NSImage(named: "folder-icon")
            
                let folder2 = Folder(forNewDocumentInDatabase: databaseManager.database)
            
                folder2.title = "Another Folder"
                folder2.icon = NSImage(named: "folder-icon")

                // We must have ids before we can store the children
            
                try folder1.save()
                try folder2.save()
            
            let foldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            foldersSection.title = NSLocalizedString("Folders & Files", comment: "Folders section title")
            foldersSection.index = 2
            foldersSection.file_extension = DataTypes.Folders.ext
            foldersSection.mime_type = DataTypes.Folders.mime
            foldersSection.uti = DataTypes.Folders.uti
            
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

                try smart1.save()
                try smart2.save()

            let smartFoldersSection = Section(forNewDocumentInDatabase: databaseManager.database)
            
            smartFoldersSection.title = NSLocalizedString("Smart Folders", comment: "Folders section title")
            smartFoldersSection.index = 3
            smartFoldersSection.file_extension = DataTypes.SmartFolders.ext
            smartFoldersSection.mime_type = DataTypes.SmartFolders.mime
            smartFoldersSection.uti = DataTypes.SmartFolders.uti

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
        
        (self.searchService as! CLuceneSearchService).generalTextFields.append("q")
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

