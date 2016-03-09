//
//  SourceListInspectorController.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class SourceListInspectorController: NSViewController, Databasable {
    @IBOutlet var viewContainer: NSView!

    // MARK: - Databasable Properties
    
    var databaseManager: DatabaseManager! {
        didSet { }
    }
    
    var searchService: BRSearchService! {
        didSet { }
    }
    
    // MARK: - Custom Properties
    
    dynamic var selectedObjects: [DataSource] = [] {
        willSet {
            
        }
        didSet {
            print("inspector set selected objects")
        }
    }
    
    var selectedObject: DataSource? {
        return ( selectedObjects.count == 1 ) ? selectedObjects[0] : nil
    }
    
    var inspectors: [(String, NSImage, NSViewController)] = [] {
        willSet {
            removeInspectorsFromInterface()
        }
        didSet {
            addInspectorsToInterface()
        }
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    // MARK: - Inspector Interface
    
    func removeInspectorsFromInterface() {
    
    }
    
    func addInspectorsToInterface() {
    
    }

    
    func loadInspectors() {
        guard inspectors.count > 0 else {
            return
        }
        
        let (name, icon, vc) = inspectors[0]
        
        print(name)
        
        vc.view.frame = viewContainer.bounds
        viewContainer.addSubview(vc.view)
    }
}
