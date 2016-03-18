//
//  Databasable.swift
//  South Lake
//
//  Created by Philip Dow on 2/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

protocol Databasable {
    var databaseManager: DatabaseManager? { get set}
    var searchService: BRSearchService? { get set }
}
