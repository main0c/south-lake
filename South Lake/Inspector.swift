//
//  Inspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

/// An inspector must be an instance of NSViewController that has an icon

@objc(Inspector)
protocol Inspector {
    
    /// The title is optional for an inspector and is used as a tooltip in the inspector palette
    var title: String? { get }
    
    /// An icon is required and indicates to the user what this inspector does
    var icon: NSImage { get }
}