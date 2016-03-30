//
//  FileImporter.swift
//  South Lake
//
//  Created by Philip Dow on 2/25/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

@objc(FileImporter)
protocol FileImporter {
    static var filetypes: [String] { get }
    
    init() // weird
    
    /// Return a plain text representation of your data source or nil if there is none
    
    func plainTextRepresentation(data: NSData?) -> String?
    
    /// Return a thumbnail representation of your data source or nil if there is none
    
    func thumbnail(data: NSData?) -> NSImage?
    
}