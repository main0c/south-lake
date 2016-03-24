//
//  InspectorPanel.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

/// Given a SourceViewer, knows how to display the Inspectors for it. That is its only job
/// It does not manage bindings for the inspectors, and it doesn't care what is displayed
/// in the inspectors.

class InspectorPanel: NSViewController {
    @IBOutlet var viewContainer: NSView!
    @IBOutlet var tabView: NSTabView!
    @IBOutlet var tabBar: DMTabBar!

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
        
        (self.view as! CustomizableView).backgroundColor = UI.Color.InspectorBackground
        
        // Clear the tab view
        
        for (item) in tabView.tabViewItems {
            tabView.removeTabViewItem(item)
        }
        
        // Customize the tab bar
        
        tabBar.gradientColorStart = UI.Color.InspectorBackground
        tabBar.gradientColorEnd = UI.Color.InspectorBackground
        tabBar.borderColor = NSColor(white:0.80, alpha:1.0)
    }
    
    func willClose() {
        tabBar.handleTabBarItemSelection(nil)
        tabBar.tabBarItems = nil
    }
    
    // MARK: - Inspector Interface
    
    func removeInspectorsFromInterface() {
        guard let inspectors = inspectors where inspectors.count > 0 else {
            return
        }
        
        // Tear down tab bar
        
        tabBar.tabBarItems = nil
        tabBar.handleTabBarItemSelection(nil)
        
        // Tear down the tab view
        
        for (item) in tabView.tabViewItems {
            tabView.removeTabViewItem(item)
        }
    }
    
    func addInspectorsToInterface() {
        guard let inspectors = inspectors where inspectors.count > 0 else {
            return
        }
        
        // Set up tab bar
        
        tabBar.tabBarItems = inspectors.map { (inspector) -> DMTabBarItem in
            let item = DMTabBarItem(icon: inspector.icon, selectedIcon: inspector.selectedIcon, tag: 0)
            item.toolTip = inspector.title
            return item
        }
        
        tabBar.handleTabBarItemSelection { (selectionType, item, index) -> Void in
            if selectionType == UInt(DMTabBarItemSelectionType_WillSelect) {
                self.tabView.selectTabViewItem(self.tabView.tabViewItems[Int(index)])
            }
        }
        
        // Set up tab view
        
        let tabViewItems = inspectors.map { (inspector) -> NSTabViewItem in
            let item = NSTabViewItem(viewController: inspector as! NSViewController)
            return item
        }
        
        for item in tabViewItems {
            tabView.addTabViewItem(item)
        }
    }

}
