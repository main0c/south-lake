//
//  DocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  Abstract superclass for document tabs

import Cocoa

protocol DocumentTab: class, Databasable {
    var databaseManager: DatabaseManager! { get set }
    var searchService: BRSearchService! { get set }
    
    func state() -> Dictionary<String,AnyObject>
    func restoreState(state: Dictionary<String,AnyObject>)
}