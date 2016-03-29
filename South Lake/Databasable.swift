//
//  Databasable.swift
//  South Lake
//
//  Created by Philip Dow on 2/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

/// Protocol for objects which require access to the model layer and search
/// services

protocol Databasable {
    var databaseManager: DatabaseManager? { get set}
    var searchService: BRSearchService? { get set }
}
