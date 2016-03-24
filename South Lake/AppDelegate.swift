//
//  AppDelegate.swift
//  South Lake
//
//  Created by Philip Dow on 2/15/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  TODO: still getting crashes on selection, watch that shit on bindings

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

