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
    func plainTextRepresentation(data: NSData?) -> String
}