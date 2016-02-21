//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

// TODO: mark FileEditor protocol as always belonging to class NSViewController

protocol FileEditor {
    // Should we share the File or just the data? 
    // Sharing the data shares less and makes the class more resilient to change
    // Sharing the File may allow us to have more complex editor views
    
    // Expect a tab to establish a continuous two-way binding between 
    // File.data and FileEditor.data
    
    var data: NSData? { get set }
}