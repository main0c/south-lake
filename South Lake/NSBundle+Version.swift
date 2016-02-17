//
//  NSBundle+Version.swift
//  South Lake
//
//  Created by Philip Dow on 2/16/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Access to the CFBundleShortVersionString and CFBundleVersion from the main bundle

import Foundation

extension NSBundle {

    var releaseVersionNumber: String? {
        return self.infoDictionary?["CFBundleShortVersionString"] as? String
    }

    var buildVersionNumber: String? {
        return self.infoDictionary?["CFBundleVersion"] as? String
    }

}
