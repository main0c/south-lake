//
//  Editor.swift
//  South Lake
//
//  Created by Philip Dow on 2/20/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

protocol FileEditor {
    // Should we share the File or just the data? Sharing the data shares less
    var data: NSData? { get set }
}