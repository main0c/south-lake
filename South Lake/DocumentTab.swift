//
//  DocumentTab.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

/// The DocumentTab protocol describes the methods and properties any application
/// tab is expected to implement. Most of the methods are template methods
/// called by other parts of the appliction or IBAction methods that are passed
/// down from the window controller at the top of the responder chain.

protocol DocumentTab: class, Databasable {
    
    // Databasable
    // If these are not included here I get "let constant" errors when trying to 
    // assign to the property
    
    var databaseManager: DatabaseManager? { get set }
    var searchService: BRSearchService? { get set }
 
    // Document Tab

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
    
    func changeLayout(sender: AnyObject?)
    func toggleDocumentHeader(sender: AnyObject?)
    
    // UI validation
    
    func validateMenuItem(menuItem: NSMenuItem) -> Bool
    
    // URLs
    
    func handleOpenURLNotification(notification: NSNotification)
}
