//
//  PDFEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import Quartz

class PDFEditor: NSViewController, FileEditor {
    @IBOutlet var editor: PDFView!

    // MARK: - File Editor
    
    static var filetypes: [String] { return ["com.adobe.pdf", "pdf", "application/pdf"] }
    static var storyboard: String { return "PDFEditor" }
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    var isFileEditor: Bool {
        return true
    }
    
    dynamic var file: DataSource? {
        willSet {
        
        }
        didSet {
            loadFile(file)
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: - 
    
    func loadFile(file: DataSource?) {
        guard let file = file as? File else {
            return
        }
        
        guard let document = PDFDocument(data: file.data) else {
            print("unable to initialize pdf document from file data")
            return
        }
        
        editor.setDocument(document)
        
    }
    
}
