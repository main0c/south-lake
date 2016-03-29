//
//  DataSourceViewControllerDelegate.swift
//  South Lake
//
//  Created by Philip Dow on 3/28/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

protocol DataSourceViewControllerDelegate {
    func dataSourceViewController(dataSourceViewController: DataSourceViewController, didChangeSelection selection: [AnyObject])
}