//
//  AppDelegate.swift
//  South Lake
//
//  Created by Philip Dow on 2/15/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    let documentController = DocumentController()

    func applicationDidFinishLaunching(aNotification: NSNotification) {
        // Insert code here to initialize your application
        
        // Reset user defaults
        // NSUserDefaults.standardUserDefaults().setPersistentDomain([:], forName: NSBundle.mainBundle().bundleIdentifier!)
        
        MacDownCopyFiles.copyFiles()
    }

    func applicationWillTerminate(aNotification: NSNotification) {
        // Insert code here to tear down your application
    }
    
}

func log<T>(message: T, file: String = __FILE__, line: Int = __LINE__, function: String = __FUNCTION__) {
    log("\((file as NSString).lastPathComponent).\(function)[\(line)]: \(message)")
}