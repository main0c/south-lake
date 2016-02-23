//
//  EditorExtensions.swift
//  South Lake
//
//  Created by Philip Dow on 2/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class EditorExtensions {
    static let sharedInstance = EditorExtensions()
    private var editors: [ [String:AnyObject] ] = []
    
    private init() {
        self.registerExtensions()
    }
    
    func registerExtensions() {
        // Store this information in a bundle plist
        // Just need the bundle, storyboard name and filetypes
        
        editors = [
            [
                "filetypes": ["net.daringfireball.markdown", "markdown", "text/markdown"],
                "storyboard": "MarkdownEditor"
            ]
        ]
    }
    
    func editorForFiletype(filetype: String) -> FileEditor? {
        var storyboard: String?
        
        for editor in editors {
            guard let filetypes = editor["filetypes"] as? [String],
                  let sb = editor["storyboard"] as? String
                  where !filetypes.contains(filetype) else {
                  continue
            }
            
            storyboard = sb
            break
        }
        
        guard storyboard != nil else {
            return nil
        }
        
        return NSStoryboard(name: storyboard!, bundle: nil).instantiateInitialController() as? FileEditor
    }
}
