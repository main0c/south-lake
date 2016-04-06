//
//  NSSplitViewController+Replace.swift
//  South Lake
//
//  Created by Philip Dow on 3/26/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

extension NSSplitViewController {
    func replaceSplitViewItem(atIndex index: Int, withViewController viewController: NSViewController) {
        assert(index <= splitViewItems.count)
        
        guard splitViewItems[index].viewController != viewController else {
            return
        }
        
        // Note item settings
        
        let holdingPriority = splitViewItems[index].holdingPriority
        let collapsed = splitViewItems[index].collapsed
        
        // Set up the frame
            
        let frame = splitViewItems[index].viewController.view.frame
        viewController.view.frame = frame
        
        // Create a new item
        
        let newItem = NSSplitViewItem(viewController: viewController)
        
        // Move it into place
        
        removeSplitViewItem(splitViewItems[index])
        insertSplitViewItem(newItem, atIndex: index)
        
        // Restore settings
        
        newItem.holdingPriority = holdingPriority
        newItem.collapsed = collapsed
    }
}