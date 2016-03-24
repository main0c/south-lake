//
//  PDFEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import Quartz

class PDFEditor: NSViewController, SourceViewer {
    @IBOutlet var editor: PDFView!

    // MARK: - File Editor
    
    static var filetypes: [String] { return ["com.adobe.pdf", "pdf", "application/pdf"] }
    static var storyboard: String { return "PDFEditor" }
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    var isFileEditor: Bool {
        return true
    }
    
    dynamic var source: DataSource? {
        didSet {
            loadFile(source)
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        loadThumbnailInspector()
        guard let vc = thumbnailInspector else {
            return nil
        }
        return [vc]
    }
    
    // MARK: - My Properties
    
    var thumbnailInspector: PDFThumbnailInspector?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        editor.setBackgroundColor(UI.Color.SourceViewerBackground)
    }
    
    func willClose() {
    
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
    
    // TODO: dynamically return individual inspector views as they are needed?
    
    func loadThumbnailInspector() {
        guard thumbnailInspector == nil else {
            return
        }
        
        thumbnailInspector = storyboard!.instantiateControllerWithIdentifier("thumbnail") as? PDFThumbnailInspector
        
        thumbnailInspector!.databaseManager = databaseManager
        thumbnailInspector!.searchService = searchService
        
        let _ = thumbnailInspector!.view
        thumbnailInspector!.thumbnailView.setPDFView(editor)
    }
    
    // MARK: - 
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
    
    }
}
