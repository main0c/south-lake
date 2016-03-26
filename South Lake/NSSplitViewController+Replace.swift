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
        
        // Set up the frame
            
        let frame = splitViewItems[index].viewController.view.frame
        viewController.view.frame = frame
        
        // Move it into place
        
        let newIem = NSSplitViewItem(viewController: viewController)
        
        removeSplitViewItem(splitViewItems[index])
        insertSplitViewItem(newIem, atIndex: index)
    }
}