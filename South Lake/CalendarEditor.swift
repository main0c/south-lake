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
    @IBOutlet var bottomContainerViewConstraint: NSLayoutConstraint!
    @IBOutlet var pathControl: NSPathControlWithCursor!
    @IBOutlet var searchField: NSSearchField!
    @IBOutlet var countField: NSTextField!
    @IBOutlet var bottomDivider: NSBox!
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    var selectionDelegate: SelectionDelegate?
    dynamic var source: DataSource?
    
    var scene: Scene = .None {
        didSet { if scene != oldValue {
            loadScene(scene)
        }}
    }
    
    var layout: Layout = .None {
        didSet { if layout != oldValue {
            loadLayout(layout)
        }}
    }
        
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
    
    // MARK: - Layout and Scene
    
    func loadLayout(layout: Layout) {
                
        guard viewLoaded else {
            return
        }
        
        if layout == .Horizontal {
            bottomContainerViewConstraint.constant = 0
            bottomDivider.hidden = true
            searchField.hidden = true
            countField.hidden = true
        } else {
            bottomContainerViewConstraint.constant = 27
            bottomDivider.hidden = false
            searchField.hidden = false
            countField.hidden = false
        }
    }
    
    func loadScene(scene: Scene) {
    
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
