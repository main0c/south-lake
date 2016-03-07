//
//  CalendarEditor.swift
//  South Lake
//
//  Created by Philip Dow on 3/6/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class CalendarEditor: NSViewController, FileEditor {

   static var filetypes: [String] { return ["southlake.notebook.calendar", "southlake/x-notebook-calendar", "southlake-notebook-calendar"] }
    static var storyboard: String { return "CalendarEditor" }
    
    dynamic var file: DataSource? {
        willSet {
        
        }
        didSet {
        
        }
    }
    
    var primaryResponder: NSView {
        return view
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
