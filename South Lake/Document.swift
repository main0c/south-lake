//
//  Document.swift
//  South Lake
//
//  Created by Philip Dow on 2/15/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

enum DocumentError: ErrorType {
    case ShouldNotSaveFileWrapper
    case ShouldNotReadFileWrapper
    
    case InvalidDocumentURL
    case InvalidDatabaseURL
    case InvalidLuceneURL
    
    case CouldNotInitializeDatabase
    case CouldNotInitializeSearch
}

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

    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override func windowControllerDidLoadNib(aController: NSWindowController) {
        super.windowControllerDidLoadNib(aController)
        // Add any code here that needs to be executed once the windowController has loaded the document's window.
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: "Main", bundle: nil)
        let windowController = storyboard.instantiateControllerWithIdentifier("Document Window Controller") as! NSWindowController
        self.addWindowController(windowController)
    }

    // File handling
    
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
        
        // Initialize database and search
            
        try self.initializeDatabase(databaseURL)
        try self.initializeLucene(luceneURL)
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
            
            // Hide extension: should be unnecessary
            
            do { try NSFileManager().setAttributes([NSFileExtensionHidden: true], ofItemAtPath: path) } catch {
                print(error)
            }
            
            // Initialize database and search
            
            do { try self.initializeDatabase(databaseURL) } catch {
                completionHandler(error as NSError)
            }
            
            do { try self.initializeLucene(luceneURL) } catch {
                completionHandler(error as NSError)
            }
            
            // TODO: document.json
            
            self.bootstrapDatabase()
            self.bootstrapLucene()
            
            completionHandler(nil)
        }
    }
    
    override func saveDocument(sender: AnyObject?) {
        // Disable saving or use for sync
        do { try databaseManager.database.saveAllModels() } catch {
            print(error)
        }
    }
    
    // Seriously though, disable autosaving
    
    override func autosaveDocumentWithDelegate(delegate: AnyObject?, didAutosaveSelector: Selector, contextInfo: UnsafeMutablePointer<Void>) {
        return
    }
    
    // Initialize and bootstrap database and search
    
    func databaseURL(documentURL: NSURL) -> NSURL? {
        return documentURL
    }
    
    func luceneURL(documentURL: NSURL) -> NSURL? {
        guard let documentPath = documentURL.path else {
            return nil
        }
        
        let path = (documentPath as NSString).stringByAppendingPathComponent("lucene")
        return NSURL(fileURLWithPath:path)
    }
    
    func initializeDatabase(url: NSURL) throws {
        do { self.databaseManager = try DatabaseManager(url: url) } catch {
            throw DocumentError.CouldNotInitializeDatabase
        }
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
    
    func bootstrapDatabase() {
    
    }
    
    func bootstrapLucene() {
    
    }
}

