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
    
    let styling =
    "<html>" +
        "<head>" +
            "<style>" +
                "html, body {" +
                    "margin: 5px;" +
                    "padding: 5px; " +
                    "font-family: 'HelveticaNeue', 'Helvetica Neue', 'Helvetica Neue', Arial, Helvetica, sans-serif;" +
                    "font-size: 11px;" +
                    "background-color: rgb(243, 243, 243)" +
                "}" +
                "a {" +
                    "text-decoration: none;" +
                "}" +
                "ul {" +
                    "margin: 0 0 0 5px;" +
                    "padding: 0; " +
                "}" +
                "li {" +
                    "margin: 5px 0;" +
                "}" +
                "h3 {" +
                    "margin: 0;" +
                    "padding: 0;" +
                    "font-weight: normal;" +
                "}" +
            "</style>" +
        "</head>" +
        "<body>" +
            "<h3>Comments</h3>" +
            "{{comments}}" +
        "</body>" +
    "</html>"
    
    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "comments-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named: "comments-selected-icon")!
    }
    
    // MARK: - Initialization

    override func viewDidLoad() {
        super.viewDidLoad()
        
//        let html = styling.stringByReplacingOccurrencesOfString("{{comments}}", withString: "Commenting not yet available")
//        webView.mainFrame.loadHTMLString(html, baseURL: NSURL(string: "/"))
        
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
    
}
