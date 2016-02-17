//
//  DocumentTabController.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

//  Create and destroy tabs, persist and restore them.

import Cocoa

enum DocumentTabControllerError: ErrorType {
    case CouldNotInstantiateTabViewController
}

class DocumentTabController: NSViewController {
    @IBOutlet var tabBarView: MMTabBarView!
    @IBOutlet var tabView: NSTabView!
    
    var databaseManager: DatabaseManager! {
        didSet {
            // TODO: refactor into forEachTab method that takes a closure
            for vc in tabView.tabViewItems.map({($0.vc as! DocumentTab)}) {
                vc.databaseManager = databaseManager
            }
        }
    }
    
    var searchService: BRSearchService! {
        didSet {
            for vc in tabView.tabViewItems.map({($0.vc as! DocumentTab)}) {
                vc.searchService = searchService
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tabBarView.setStyleNamed("Yosemite")
        tabBarView.setShowAddTabButton(true)
        tabBarView.setOrientation(MMTabBarHorizontalOrientation)
        tabBarView.setHideForSingleTab(false)
        tabBarView.setAllowsBackgroundTabClosing(true)
        tabBarView.setAutomaticallyAnimates(true)
        tabBarView.setOnlyShowCloseOnHover(true)
        tabBarView.setDisableTabClose(false)
        tabBarView.setButtonMinWidth(100)
        tabBarView.setButtonMaxWidth(280)
        tabBarView.setButtonOptimumWidth(130)
        
        for (item) in tabView.tabViewItems {
            tabView.removeTabViewItem(item)
        }
        
        do { try createNewTabWithTitle("Tab One") } catch {
            print("viewDidLoad: could not create new tab")
        }
    }
    
    @IBAction func createNewTab(sender: AnyObject) {
        do { try createNewTabWithTitle(NSLocalizedString("Untitled", comment: "Untitled tab")) } catch {
            print("createNewTab: could not create new tab")
        }
    }
    
    @IBAction func closeTab(sender: AnyObject) {
        print("close tab")
    }
    
    @IBAction func selectNextTab(sender: AnyObject) {
        if tabView.indexOfTabViewItem(tabView.selectedTabViewItem!) == tabView.numberOfTabViewItems-1 {
            tabView.selectFirstTabViewItem(sender)
        } else {
            tabView.selectNextTabViewItem(sender)
        }
    }
    
    @IBAction func selectPreviousTab(sender: AnyObject) {
        if tabView.indexOfTabViewItem(tabView.selectedTabViewItem!) == 0 {
            tabView.selectLastTabViewItem(sender)
        } else {
            tabView.selectPreviousTabViewItem(sender)
        }
    }
    
    func createNewTabWithTitle(title: String) throws {
        guard let viewController = NSStoryboard(name: "Tab", bundle: nil).instantiateInitialController() as? DocumentTab else {
            throw DocumentTabControllerError.CouldNotInstantiateTabViewController
        }
        
        let tabBarItem = DocumentTabBarItem(title: title)
        let tabViewItem = NSTabViewItem(identifier: tabBarItem)
        
        tabViewItem.view = viewController.view
        tabViewItem.vc = viewController
        
        viewController.databaseManager = databaseManager
        viewController.searchService = searchService
        
        tabBarItem.bind("title", toObject: viewController, withKeyPath: "title", options: [:])
        viewController.title = title
        
        tabView.addTabViewItem(tabViewItem)
        tabView.selectTabViewItem(tabViewItem)
    }
    
    // MARK: - Document State
    
    func state() -> Dictionary<String,AnyObject> {
        var tabStates: [AnyObject] = []
        
        for vc in tabView.tabViewItems.map({($0.vc as! DocumentTab)}) {
            tabStates.append(vc.state())
        }
        
        return ["Tabs": tabStates]
    }
    
    func initializeState(state: Dictionary<String,AnyObject>) {
        if let tabStates = state["Tabs"] as? [Dictionary<String,AnyObject>] {
            for (item) in tabView.tabViewItems {
                tabView.removeTabViewItem(item)
            }
            for tabState in tabStates {
                let title = (tabState["Title"] ?? NSLocalizedString("Untitled", comment: "Untitled tab")) as! String
                do { try createNewTabWithTitle(title) } catch {
                    print("initializeState: unable to restore a tab")
                }
            }
        }
    }
}

// MARK: - MMTabBarViewDelegate

extension DocumentTabController: MMTabBarViewDelegate {
    
    func addNewTabToTabView(tabView: NSTabView) {
        createNewTab(tabView)
    }
    
    func tabView(aTabView: NSTabView!, didCloseTabViewItem tabViewItem: NSTabViewItem!) {
        // print("didCloseTabViewItem: \(tabViewItem!.label)")
    }
    
    func tabView(tabView: NSTabView, didSelectTabViewItem tabViewItem: NSTabViewItem?) {
        // print("didSelectTabViewItem: \(tabViewItem!.label)")
    }
}

// MARK: - DocumentTabBarItem

class DocumentTabBarItem: NSObject, MMTabBarItem {
    var title: String = NSLocalizedString("Untitled", comment: "Untitled tab")
    var hasCloseButton: Bool = true
    var icon: NSImage?
    
    init(title: String) {
        self.title = title
    }
}
