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
    
    var inspectors: [(String, NSImage, NSViewController)]? {
        loadThumbnailView()
        guard let vc = thumbnailViewController,
              let icon = NSImage(named:"pdf-thumbnails-icon") else {
              return []
        }
        return [(NSLocalizedString("Thumbnails", comment:""), icon, vc)]
    }
    
    // MARK: - My Properties
    
    var thumbnailViewController: PDFThumbnailViewController?
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        editor.setBackgroundColor(NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0))
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
    
    func loadThumbnailView() {
        guard thumbnailViewController == nil else {
            return
        }
        
        thumbnailViewController = storyboard!.instantiateControllerWithIdentifier("thumbnail") as? PDFThumbnailViewController
        
        thumbnailViewController?.thumbnailView.setPDFView(editor)
    }
    
}