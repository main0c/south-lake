//
//  LibrarySceneProtocol.swift
//  South Lake
//
//  Created by Philip Dow on 3/7/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

protocol LibraryScene: Databasable {
    // Databasable
    var databaseManager: DatabaseManager! { get set }
    var searchService: BRSearchService! { get set }
    
    /// A LibraryScene is a view controller with a view property
    var view: NSView { get set }
    
    /// A LibraryScene has an NSArrayController
    var arrayController: NSArrayController! { get set }
}