//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

//  TODO: mark FileEditor protocol as always belonging to class NSViewController
//  TODO: blows up when I make available to @objc(FileEditor)

/// ### Architecture
/// Sharing full File data model rather than just the file contents so that the
/// editor has the ability to modify model metadata as file contents are edited

protocol FileEditor: class, Databasable {
    
    static var filetypes: [String] { get }
    static var storyboard: String { get }
    
    /// The default behavior of a file editor should be to ignore the databaseManager
    var databaseManager: DatabaseManager! { get set }
    
    /// The default behavior of a file editor should be to ignore the searchService
    var searchService: BRSearchService! { get set }
    
    /// A FileEditor is a view controller with a view property
    var view: NSView { get set }
    
    /// A FildEditor is a view controller that can handle child-parent relationships
    func removeFromParentViewController()
    
    /// A tab passes a file to the editor. The file may be nil. The editor may
    /// many any changes it likes to the file, including metadata changes.
    /// Editors should use the universal data: NSData interface for file contents
    
    // TODO: you can tell something's wrong because it's a DataSource called File
    
    var file: DataSource? { get set }
    
    /// The responder that take focus for editing and first responder switching
    var primaryResponder: NSView { get }
    
    /// Return true if we edit files specifically and not some other kind of data source
    var isFileEditor: Bool { get }
    
    /// A file editor can return inspectors that it manages which are placed in the inspector area
    /// An inspector consists of a tile, and icon and a view controller
    /// A metadata inspector is automatically included in the inspector area
    var inspectors: [Inspector]? { get }
}