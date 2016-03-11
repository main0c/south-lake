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
    
    var template: String?
    
//    let template =
//    "<html>" +
//        "<head>" +
//            "<style>" +
//                "html, body {" +
//                    "margin: 5px;" +
//                    "padding: 5px; " +
//                    "font-family: 'HelveticaNeue', 'Helvetica Neue', 'Helvetica Neue', Arial, Helvetica, sans-serif;" +
//                    "font-size: 11px;" +
//                    "background-color: rgb(243, 243, 243)" +
//                "}" +
//                "a {" +
//                    "text-decoration: none;" +
//                "}" +
//                "ul {" +
//                    "margin: 0 0 0 5px;" +
//                    "padding: 0; " +
//                "}" +
//                "li {" +
//                    "margin: 5px 0;" +
//                "}" +
//                "h3 {" +
//                    "margin: 0;" +
//                    "padding: 0;" +
//                    "font-weight: normal;" +
//                "}" +
//            "</style>" +
//        "</head>" +
//        "<body>" +
//            "<h3>Table of Contents</h3>" +
//            "{{toc}}" +
//        "</body>" +
//    "</html>"

    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "md-table-of-contents-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named: "md-table-of-contents-selected-icon")!
    }
    
    // MARK: - Custom Properties
    
    dynamic var tableOfContents: String? {
        didSet {
            guard let template = template else {
                return
            }
            
            let toc = tableOfContents ?? ""
            let html = template.stringByReplacingOccurrencesOfString("{{toc}}", withString: toc)
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
        
        do { template = try String(contentsOfURL: NSBundle.mainBundle().URLForResource("md-toc-index", withExtension: "html")!, encoding: NSUTF8StringEncoding) } catch {
            print(error)
        }
        
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
