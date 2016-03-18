//
//  CommentsInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import WebKit

class CommentsInspector: NSViewController, Inspector {
    @IBOutlet var webView: WebView!
    @IBOutlet var textField: NSTextField!
    
    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "comments-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named: "comments-selected-icon")!
    }
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
        
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // http://www.bypeople.com/css-chat/
        // http://codepen.io/drehimself/pen/KdXwxR?utm_source=bypeople
        
        if let URL = NSBundle.mainBundle().URLForResource("index", withExtension: "html", subdirectory: "chat-widget") {
            do {
                let html = try String(contentsOfURL: URL, encoding: NSUTF8StringEncoding)
                webView.mainFrame.loadHTMLString(html, baseURL: URL)
            } catch {
                print(error)
            }
        }
    }
    
    deinit {
        print("comments inspector deinit")
    }
    
    func willClose() {
    
    }
}
