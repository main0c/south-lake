//
//  Importer.swift
//  South Lake
//
//  Created by Philip Dow on 3/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

class Importer {
    var databaseManager: DatabaseManager
    var searchService: BRSearchService
    
    /// Destination may be a folder or nil.
    var destination: Folder?
    
    init(databaseManager: DatabaseManager, searchService: BRSearchService ) {
        self.databaseManager = databaseManager
        self.searchService = searchService
    }
    
    func importFiles(files: [NSURL]) {
        for url in files {
            if let file = importFile(url) {
                log("imported \(file)")
            } else {
                log("unable to import \(url)")
            }
        }
    }
    
    func importDirectory(directory: NSURL) {
    
    }
    
    private func importFile(URL: NSURL) -> DataSource? {
        guard let path = URL.path else {
            log("unable to determine path for url: \(URL)")
            return nil
        }
        
        var item: DataSource?
        
        autoreleasepool {
        
        // Are we a directory? if so make a folder, otherwise make a document
        // Eventually we'll recursively do this
        
        let fm = NSFileManager()
        var dir = ObjCBool(false)
        
        fm.fileExistsAtPath(URL.path!, isDirectory: &dir)
        
        if dir.boolValue {
            item = Folder(forNewDocumentInDatabase: databaseManager.database)
            
            item!.title = (URL.lastPathComponent! as NSString).stringByDeletingPathExtension
            item!.icon = NSImage(named: "folder-icon")
            item!.children = []
        } else {
            
            // TODO: may need to use an input stream or a data task. See documentation
            // TODO: must make this asynchronous
            
            var data: NSData?
            
            do { data = try NSData(contentsOfURL: URL, options: []) } catch {
                log(error)
            }
            
            guard let d = data else {
                return
            }
            
            item = File(forNewDocumentInDatabase: databaseManager.database)
            
            item!.title = (URL.lastPathComponent! as NSString).stringByDeletingPathExtension
            item!.thumbnail = NSWorkspace.sharedWorkspace().previewForFile(URL)
            item!.icon = NSWorkspace.sharedWorkspace().iconForFile(path)
            item!.file_extension = URL.fileExtension ?? "unknown"
            item!.mime_type = URL.mimeType ?? "unknown"
            item!.uti = URL.UTI ?? "unknown"
            (item as! File).data = d
        }
        
        // Save
        
        do { try item!.save() } catch {
            log(error)
            item = nil
        }
        
        } // autorelease pool
        
        return item
    }
}