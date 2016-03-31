//
//  CalendarEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class CalendarEditor: NSViewController, SelectableSourceViewer {
    static var storyboard: String = "CalendarEditor"
    static var filetypes: [String] = [
        "southlake.notebook.calendar",
        "southlake/x-notebook-calendar",
        "southlake-notebook-calendar"
    ]
    
    @IBOutlet var containerView: NSView!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var searchField: NSSearchField!
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    var selectionDelegate: SelectionDelegate?
    dynamic var source: DataSource?
    var layout: Layout = .None
    var scene: Scene = .None
        
    var primaryResponder: NSView {
        return view
    }
    
    var inspectors: [Inspector]? {
        return nil
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.SourceViewer
        
        pathControl.backgroundColor = UI.Color.Background.SourceViewer
        pathControl.URL = NSURL(string: "southlake://localhost/calendar")
        updatePathControlAppearance()
        
        searchField.appearance = NSAppearance(named: NSAppearanceNameVibrantLight)
    }
    
    // MARK: - 
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
    
    }
    
    func willClose() {
    
    }
    
    // MARK: - 
    
    func updatePathControlAppearance() {
        // First cell's string value is a capitalized, localized transformation of "tags"
        // First cell is black, remaining are blue
        
        let cells = pathControl.pathComponentCells()
        guard cells.count > 0 else {
            return
        }
        
        cells.first?.stringValue = cells.first!.stringValue.capitalizedString
        cells.first?.textColor = NSColor(white: 0.1, alpha: 1.0)
        
        for cell in cells[1..<cells.count] {
            cell.textColor = NSColor.keyboardFocusIndicatorColor()
        }
    }
}
