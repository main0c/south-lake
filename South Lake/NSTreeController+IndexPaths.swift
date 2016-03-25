//
//  NSTreeController+IndexPaths.swift
//  South Lake
//
//  Created by Philip Dow on 3/18/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  Walkin' the tree. Not great.
//  http://stackoverflow.com/questions/9050028/given-model-object-how-to-find-index-path-in-nstreecontroller

//  guard (arrangedObjects as! NSObject).respondsToSelector(Selector("childNodes")) else {
//      log("arranged objects does not respond to childNodes")
//      return nil
//  }
//  let childNodes = (arrangedObjects as! NSObject).valueForKey("childNodes")

import Foundation

extension NSTreeController {
    func indexPathOfRepresentedObject(object: AnyObject) -> NSIndexPath? {
        return indexPathOfRepresentedObject(object, nodes: arrangedObjects.childNodes)
    }
    
    private func indexPathOfRepresentedObject(object: AnyObject, nodes: [NSTreeNode]?) -> NSIndexPath? {
        guard let nodes = nodes else {
            return nil
        }
        for node in nodes {
            if let representedObject = node.representedObject where object === representedObject {
                return node.indexPath
            }
            if let childNodes = node.childNodes,
               let path = indexPathOfRepresentedObject(object, nodes: childNodes) {
                return path
            }
        }
        return nil
    }
}