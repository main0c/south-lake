//
//  SelectionDelegate.swift
//  South Lake
//
//  Created by Philip Dow on 3/28/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

protocol SelectionDelegate: class {
    func object(object: AnyObject, didChangeSelection selection: [AnyObject])
}