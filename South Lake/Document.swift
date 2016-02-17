//
//  Document.swift
//  South Lake
//
//  Created by Philip Dow on 2/15/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

enum AppDocumentError: ErrorType {
    case ShouldNotSaveFileWrapper
    case ShouldNotReadFileWrapper
    
    case CouldNotInitializeSearchService
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
            throw AppDocumentError.ShouldNotSaveFileWrapper
        }
        
        return  NSFileWrapper(directoryWithFileWrappers: [:])
    }
    
    override func readFromFileWrapper(fileWrapper: NSFileWrapper, ofType typeName: String) throws {
        throw AppDocumentError.ShouldNotReadFileWrapper
    }

    override func writeToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, originalContentsURL absoluteOriginalContentsURL: NSURL?) throws {
        try super.writeToURL(url, ofType: typeName, forSaveOperation: saveOperation, originalContentsURL: absoluteOriginalContentsURL)
    }
    
    override func readFromURL(url: NSURL, ofType typeName: String) throws {
        try databaseManager = DatabaseManager(url: url)
        
        let searchPath = (url.path! as NSString).stringByAppendingPathComponent("lucene")
        searchService = CLuceneSearchService(indexPath: searchPath)
        
        if (searchService as BRSearchService?) == nil {
            throw AppDocumentError.CouldNotInitializeSearchService
        }
    }
    
    override func saveDocument(sender: AnyObject?) {
        // Disable saving or use for sync
        do { try databaseManager.database.saveAllModels() } catch {
            print(error)
        }
    }
    
    override func saveToURL(url: NSURL, ofType typeName: String, forSaveOperation saveOperation: NSSaveOperationType, completionHandler: (NSError?) -> Void) {
        guard fileURL == nil else {
            print("Document already initialized, don't save")
            completionHandler(nil)
            return
        }
        
        super.saveToURL(url, ofType: typeName, forSaveOperation: saveOperation) { (error) -> Void in
            do { try NSFileManager().setAttributes([NSFileExtensionHidden: true], ofItemAtPath: url.path!) } catch {
                print(error)
            }
            
            do { try self.databaseManager = DatabaseManager(url: url) } catch {
                completionHandler(error as NSError)
            }
            
            let searchPath = (url.path! as NSString).stringByAppendingPathComponent("lucene")
            self.searchService = CLuceneSearchService(indexPath: searchPath)
            
            if (self.searchService as BRSearchService?) == nil {
                completionHandler(NSError(domain: "App", code: 0, userInfo: nil))
            }
            
            // TODO: document.json
            
            self.bootstrapDatabase()
            self.bootstrapSearch()
            
            completionHandler(nil)
        }
    }
    
    // Seriously though, disable autosaving
    
    override func autosaveDocumentWithDelegate(delegate: AnyObject?, didAutosaveSelector: Selector, contextInfo: UnsafeMutablePointer<Void>) {
        return
    }
    
    // Initialize and bootstrap database and search
    
    func bootstrapDatabase() {
    
    }
    
    func bootstrapSearch() {
    
    }
}

