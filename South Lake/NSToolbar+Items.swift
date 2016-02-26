//
//  NSToolbar+Items.swift
//  South Lake
//
//  Created by Philip Dow on 2/25/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSToolbar {
    func itemWithIdentifier(identifier: String) -> NSToolbarItem? {
        for item in items where item.itemIdentifier == identifier {
            return item
        }
        return nil
    }
}