//
//  EditorPlugIns.swift
//  South Lake
//
//  Created by Philip Dow on 2/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class EditorPlugIns {
    static let sharedInstance = EditorPlugIns()
    private var plugins: [ [String:AnyObject] ] = []
    
    private init() {
        self.registerPlugIns()
    }
    
    func registerPlugIns() {
        // Store this information in a bundle plist
        // Just need the bundle, storyboard name and filetypes
        
        plugins = [
            [
                "filetypes": ["net.daringfireball.markdown", "markdown", "text/markdown"],
                "storyboard": "MarkdownEditor"
            ],
            [
                "filetypes": ["com.adobe.pdf", "pdf", "application/pdf"],
                "storyboard": "PDFEditor"
            ],
            [
                "filetypes": ["southlake.notebook.library", "southlake/x-notebook-library", "southlake-notebook-library"],
                "storyboard": "LibraryEditor"
            ],
            [
                "filetypes": ["southlake.notebook.tags", "southlake/x-notebook-tags", "southlake-notebook-tags"],
                "storyboard": "TagsEditor"
            ],
            [
                "filetypes": ["southlake.notebook.calendar", "southlake/x-notebook-calendar", "southlake-notebook-calendar"],
                "storyboard": "CalendarEditor"
            ]
        ]
    }
    
    func plugInForFiletype(filetype: String) -> FileEditor? {
        var storyboard: String?
        
        for plugin in plugins {
            guard let filetypes = plugin["filetypes"] as? [String],
                  let sb = plugin["storyboard"] as? String else {
                  continue
            }
            
            if filetypes.contains(filetype) {
                storyboard = sb
                break
            }
        }
        
        guard storyboard != nil else {
            return nil
        }
        
        return NSStoryboard(name: storyboard!, bundle: nil).instantiateInitialController() as? FileEditor
    }
}
