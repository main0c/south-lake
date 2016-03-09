//
//  MarkdownTOCInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import WebKit

class MarkdownTOCInspector: NSViewController, Inspector {
    @IBOutlet var webView: WebView!

    // Almost certainly want to move this
    
    let styling =
    "<html>" +
        "<head>" +
            "<style>" +
                "html, body {" +
                    "margin: 5px;" +
                    "padding: 5px; " +
                    "font-family: 'HelveticaNeue', 'Helvetica Neue', 'Helvetica Neue', Arial, Helvetica, sans-serif;" +
                    "font-size: 11px;" +
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
            "</style>" +
        "</head>" +
        "<body>" +
            "<h3>Table of Contents</h3>" +
            "{{toc}}" +
        "</body>" +
    "</html>"

    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "table-of-contents-icon")!
    }
    
    // MARK: - Custom Properties
    
    dynamic var tableOfContents: String = "" {
        didSet {
            let html = styling.stringByReplacingOccurrencesOfString("{{toc}}", withString: tableOfContents)
            webView.mainFrame.loadHTMLString(html, baseURL: NSURL(string: "/"))
        }
    }
    
    // Could use a delegate method here
    
    dynamic var tableOfContentsAnchor = "" {
        didSet {
        
        }
    }
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        webView.policyDelegate = self
    }

}

// MARK: - WebPolicyDelegate

extension MarkdownTOCInspector: WebPolicyDelegate {
    
    func webView(webView: WebView!, decidePolicyForNavigationAction actionInformation: [NSObject : AnyObject]!, request: NSURLRequest!, frame: WebFrame!, decisionListener listener: WebPolicyDecisionListener!) {
        
        if let url = request.URL, fragment = url.fragment {
            tableOfContentsAnchor = fragment
            listener.ignore()
        } else {
            listener.use()
        }
    }
    
}
