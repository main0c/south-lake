//
//  MoveToMenuBuilder.swift
//  South Lake
//
//  Created by Philip Dow on 3/22/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

class MoveToMenuBuilder {
    var databaseManager: DatabaseManager
    var selection: [DataSource]?
    var action: Selector
    
    var parents = Set<DataSource>()
    
    // MARK: - Initialization
    
    init(databaseManager: DatabaseManager, action: Selector, selection: [DataSource]?) {
        self.databaseManager = databaseManager
        self.selection = selection
        self.action = action
        
        prepareParents(selection)
    }
    
    func prepareParents(items: [DataSource]?) {
        guard let items = items else {
            return
        }
        
        for item in items {
            parents = parents.union(item.parents)
        }
    }
    
    // MARK: - Menu Building
    
    func menu() -> NSMenu? {
        guard let section = databaseManager.foldersSection else {
            return nil
        }
        
        let menu = NSMenu(title: NSLocalizedString("Move To", comment: ""))
        let folders = section.children.filter { $0 is Folder }
        
        for folder in folders as! [Folder] {
            let item = menuItemForFolder(folder)
            menu.addItem(item)
        }
        
        return menu
    }
    
    private func menuItemForFolder(item: Folder) -> NSMenuItem {
        let menuItem = NSMenuItem(title: item.title, action: Selector("executeMoveTo:"), keyEquivalent: "")
        
        menuItem.representedObject = item
        
        // Image
        
        if let image = item.icon?.copy() as? NSImage {
            image.size = NSMakeSize(16,16)
            menuItem.image = image
        }
        
        // State
        // If all items are in this folder: NSOnState
        // If some items are in the folder: NSMixedState
        
        if parents.contains(item) {
            menuItem.state = NSOnState
        }
        
        // Submenu
        
        let subfolders = item.children.filter{ $0 is Folder }
        
        if subfolders.count > 0 {
            let submenu = NSMenu(title: menuItem.title)
            for subfolder in subfolders as! [Folder] {
                let item = menuItemForFolder(subfolder)
                submenu.addItem(item)
            }
            menuItem.submenu = submenu
        }
        
        // Done
        
        return menuItem
    }
}