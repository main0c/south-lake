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
    
    /// Called immediately before the scene is removed from the view hierarchy
    func willClose()
}