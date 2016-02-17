//
//  DocumentController.swift
//  South Lake
//
//  Created by Philip Dow on 2/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

enum AppDocumentControllerError: ErrorType {
    case NewDocumentNotSaved
    case NewDocumentNotCreated
}

class DocumentController: NSDocumentController {
    
    override func openUntitledDocumentAndDisplay(displayDocument: Bool) throws -> NSDocument {
        let document = try super.openUntitledDocumentAndDisplay(false) as! Document
        let savePanel = NSSavePanel()
        
        savePanel.allowedFileTypes = ["southlake"]
        savePanel.extensionHidden = true
        
        let result = savePanel.runModal()
        
        guard result == NSModalResponseOK else {
            throw AppDocumentControllerError.NewDocumentNotSaved
        }
        
        guard let URL = savePanel.URL else {
            throw AppDocumentControllerError.NewDocumentNotSaved
        }
        
        document.saveToURL(URL, ofType: defaultType!, forSaveOperation: .SaveOperation) { (error) -> Void in
            // Save callback is executed after document is returned
            guard error == nil else {
                print(error)
                return
            }
            
            // Make and show windows, normally handled by displayDocument = true
            
            self.displayDocument(document)
        }

        return document
    }
    
    func displayDocument(document: NSDocument) {
        document.makeWindowControllers()
        document.showWindows()
    }
}
