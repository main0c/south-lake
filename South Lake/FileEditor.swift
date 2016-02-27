//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

//  TODO: mark FileEditor protocol as always belonging to class NSViewController

//  Architecture
//  Should we share the File or just the data?
//  Sharing the data shares less and makes the class more resilient to change
//  Sharing the File may allow us to have more complex editor views
//  For example, allowing local edits to change the title or metadata

//  TODO: blows up when I make available to @objc(FileEditor)

protocol FileEditor {
    
    static var filetypes: [String] { get }
    static var storyboard: String { get }
    
    /// A tab establishes a continuous two-way binding between the selected 
    /// `File.data` and the `FileEditor.data`.
    
    var data: NSData? { get set }
    
    /// Editors may do something differently when they are working with a newly
    /// created document rather than a previously existing one.
    
    var newDocument: Bool { get set }
}