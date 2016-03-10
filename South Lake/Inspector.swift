//
//  Inspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

/// An inspector must be an instance of NSViewController that has an icon

/// There are two kinds of inspectors: model inspectors and editor inspectors.
///
/// A model inspector needs access to the file object. The data it shows and which
/// it allows the user to edit depend only on the model. An example of a file
/// inspector is the metadata inspector. A file inspector does not have access to
/// the file's editor instance.
///
/// An editor inspector works with the visual editor for a file and so needs access
/// to that interface (FileEditor protocol). An editor inspector doesn't have default
/// access to the file, although an editor can provide that. An example editor
/// inspector is a PDF thumbnail view that requires access to the PDF viewer
/// to display thumbnails and scroll the viewer when a thumbnail is selected.

@objc(Inspector)
protocol Inspector {
    
    /// The title is optional for an inspector and is used as a tooltip in the inspector palette
    var title: String? { get }
    
    /// An icon is required and indicates to the user what this inspector does
    var icon: NSImage { get }
    
    /// A selected icon is required. It should be a bolder or filled in version of the icon
    var selectedIcon: NSImage { get }
    
}