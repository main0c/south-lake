//
//  SearchResults.swift
//  South Lake
//
//  Created by Philip Dow on 3/12/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: Deprecated

import Cocoa

@objc(SearchResults)
class SearchResults: DataSource {
    override class var model_mime_type: NSString { return "southlake/search-results" }
    override class var model_uti: NSString { return "southlake.search-results" }
    override class var model_type: NSString { return "search_results" }
}

extension SearchResults {
    var leaf: Bool { return true }
}