//
//  DocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  Abstract superclass for document tabs

import Cocoa

protocol DocumentTab: class, Databasable {
    
    // Databasable
    
    var databaseManager: DatabaseManager! { get set }
    var searchService: BRSearchService! { get set }
 
    // Document Tab
 
    var selectedObjects: [DataSource] { get set }
    
    var title: String? { get set }
    var icon: NSImage? { get set }
    
    func state() -> Dictionary<String,AnyObject>
    func restoreState(state: Dictionary<String,AnyObject>)
    
    // Make necessary modifications to the database before it's saved
    
    func documentWillSave(notification: NSNotification) // would be awesome to register this here
    func willClose()
    
    // Search
    
    func performSearch(text: String?, results: BRSearchResults?)
    
    // User actions
    
    func createNewMarkdownDocument(sender: AnyObject?)
    func createNewSmartFolder(sender: AnyObject?)
    func createNewFolder(sender: AnyObject?)
    
    func makeFilesAndFoldersFirstResponder(sender: AnyObject?)
    func makeEditorFirstResponder(sender: AnyObject?)
    func makeFileInfoFirstResponder(sender: AnyObject?)
    
    // UI validation
    
    func validateMenuItem(menuItem: NSMenuItem) -> Bool
    
    // URLs
    
    func handleOpenURL(notification: NSNotification)
}

//extension DocumentTab where Self: NSViewController {
//    func documentWillSave() {
//    
//    }
//    
//    func willClose() {
//    
//    }
//}