//
//  SouthLakeUI.swift
//  South Lake
//
//  Created by Philip Dow on 3/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

struct UI {
    struct Color {
        struct Background {
            static let Inspector = NSColor(red: 242.0/255.0, green: 245.0/255.0, blue: 248.0/255.0, alpha: 1.0) // 236
            static let DataSourceViewController = NSColor(red: 243.0/255.0, green: 243.0/255.0, blue: 243.0/255.0, alpha: 1.0)
            static let FileHeader = NSColor(white: 1.0, alpha: 1.0)
            static let Neutral = NSColor(white: 1.0, alpha: 1.0)
        }
        struct Selection {
            static let KeyView = NSColor(red: 238.0/255.0, green: 246.0/255.0, blue: 255.0/255.0, alpha: 1.0)
            static let NotKeyView = NSColor(red: 246.0/255.0, green: 246.0/255.0, blue: 246.0/255.0, alpha: 1.0)
        }
    }
    
    struct Pasteboard {
        struct Type {
            static let File = "SouthLake.UI.Pasteboard.Type.File"
        }
    }
}