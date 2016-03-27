//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

//  TODO: mark SourceViewer protocol as always belonging to class NSViewController
//  TODO: blows up when I make available to @objc(SourceViewer)

/// ### Architecture
/// Sharing full File data model rather than just the file contents so that the
/// editor has the ability to modify model metadata as file contents are edited

protocol SourceViewer: class, Databasable {
    
    // Databasable
    
    var databaseManager: DatabaseManager? { get set }
    var searchService: BRSearchService? { get set }
    
    static var filetypes: [String] { get }
    static var storyboard: String { get }
    
    /// A SourceViewer is a view controller with a view property
    var view: NSView { get set }
    
    /// A SourceViewer is a view controller that can handle child-parent relationships
    func removeFromParentViewController()
    
    /// A tab passes a file to the editor. The file may be nil. The editor may
    /// many any changes it likes to the file, including metadata changes.
    /// Editors should use the universal data: NSData interface for file contents
    
    var source: DataSource? { get set }
    
    /// The responder that take focus for editing and first responder switching
    var primaryResponder: NSView { get }
    
    // These three really belong to folder source viewers and not file source viewers {
    
        /// Return true if we edit files specifically and not some other kind of data source
        var isFileEditor: Bool { get }
        
        /// Some source viewers can themselves have selected objects. This variable should be dynamic
        var selectedObjects: [DataSource]? { get }
        
        /// Some source viewers may be able to change their presentation based on the scene preference
        var scene: Scene { get set }
    
    // }
    
    /// A file editor can return inspectors that it manages which are placed in the inspector area
    /// An inspector consists of a tile, and icon and a view controller
    /// A metadata inspector is automatically included in the inspector area
    var inspectors: [Inspector]? { get }
    
    /// A file editor should take special action if a search is being performed, 
    /// such as highlighting the search term
    func performSearch(text: String?, results: BRSearchResults?)
    
    /// In most cases a file editor won't need to handle open urls but some of the 
    /// special editors such as the library and tag editors do need to
    func openURL(url: NSURL)
    
    /// Called immediately before the editor is removed from the view hierarchy
    /// Editors should clean up, for example, unbinding
    func willClose()
}