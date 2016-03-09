//
//  InspectorViewController.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

/// Given a FileEditor, knows how to display the Inspectors for it. That is its only job
/// It does not manage bindings for the inspectors, and it doesn't care what is displayed
/// in the inspectors.

class InspectorViewController: NSViewController {
    @IBOutlet var viewContainer: NSView!

    // MARK: - Custom Properties
    
    var inspectors: [Inspector]? {
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
        guard let inspectors = inspectors where inspectors.count > 0 else {
            return
        }
        
        let vc = inspectors[0] as! NSViewController
        vc.view.removeFromSuperview()
    }
    
    func addInspectorsToInterface() {
        guard let inspectors = inspectors where inspectors.count > 0 else {
            return
        }
        
        let vc = inspectors[0] as! NSViewController
        
        // Frame
        
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.frame = viewContainer.bounds
        viewContainer.addSubview(vc.view)
        
        // Layout Constraints
        
        viewContainer.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("H:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": vc.view])
        )
        viewContainer.addConstraints(
            NSLayoutConstraint.constraintsWithVisualFormat("V:|-0-[subview]-0-|", options: .DirectionLeadingToTrailing, metrics: nil, views: ["subview": vc.view])
        )
        
        vc.view.frame = viewContainer.bounds
        viewContainer.addSubview(vc.view)
    }

}
