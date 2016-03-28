//
//  FileCollectionSceneProtocol.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  For example: FileCardView, FileTableView, FileListView

import Foundation

protocol FileCollectionScene: Databasable {
    // Databasable
    var databaseManager: DatabaseManager? { get set }
    var searchService: BRSearchService? { get set }
    
    /// A FileCollectionScene is a view controller with a view property
    var view: NSView { get set }
    
    /// A FileCollectionScene has an NSArrayController
    var arrayController: NSArrayController! { get set }
    
    /// The FileCollectionScene should maintain a dynamic variable for selected objects
    var selectedObjects: [DataSource]? { get set }
    
    /// Depending on the layout it may only be appropriate to change the selection on a double click
    var selectsOnDoubleClick: Bool { get set }
    
    /// Called immediately before the scene is removed from the view hierarchy
    func willClose()
    
    /// Used with compact layouts, the collection may have different representaiton
    func minimize()
    
    /// Used with horizontal and expanded, the collection may have a different representation
    func maximize()
}