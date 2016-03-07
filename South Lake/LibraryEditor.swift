//
//  LibraryEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class LibraryEditor: NSViewController, FileEditor {
    @IBOutlet var collectionView: NSCollectionView!
    
    // MARK: - File Editor
    
    static var filetypes: [String] { return ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"] }
    static var storyboard: String { return "LibraryEditor" }
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    dynamic var file: DataSource? {
        willSet {
        
        }
        didSet {
            loadLibrary()
        }
    }
    
    var primaryResponder: NSView {
        return view
    }
    
    // MARK: - Custom Properties
    
    dynamic var content: [DataSource] = [] {
        didSet {
            print(content)
        }
    }

    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        (view as! CustomizableView).backgroundColor = NSColor(white: 0.94, alpha: 1.0)
        
        collectionView.itemPrototype = storyboard!.instantiateControllerWithIdentifier("collectionViewItem") as? NSCollectionViewItem
        
        loadLibrary()
    }
    
    func loadLibrary() {
        guard (databaseManager as DatabaseManager?) != nil else {
            return
        }
        
        do {
            let query = databaseManager.fileQuery
            let results = try query.run()
            var files: [File] = []
            
            while let row = results.nextRow() {
                if let document = row.document {
                    let file = CBLModel(forDocument: document) as! File
                    files.append(file)
                }
            }
            
//            sections.sortInPlace({ (x, y) -> Bool in
//                return x.index < y.index
//            })
            
            self.content = files
        } catch {
            print(error)
        }
    }
    
}

extension LibraryEditor: NSCollectionViewDelegate {

}
