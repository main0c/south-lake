//
//  CalendarEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class CalendarEditor: NSViewController, DataSourceViewController, Databasable {
    static var storyboard: String = "CalendarEditor"
    static var filetypes: [String] = [
        "southlake.notebook.calendar",
        "southlake/x-notebook-calendar",
        "southlake-notebook-calendar"
    ]
    
    @IBOutlet var containerView: NSView!
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // TODO: what is this used for?
    
    var isFileEditor: Bool {
        return false
    }
    
    var delegate: SelectionDelegate?
    dynamic var selectedObjects: [DataSource]?
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
        
        (view as! CustomizableView).backgroundColor = UI.Color.Background.DataSourceViewController
    }
    
    // MARK: - 
    
    func performSearch(text: String?, results: BRSearchResults?) {
    
    }
    
    func openURL(url: NSURL) {
    
    }
    
    func willClose() {
    
    }
}
