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
    
    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "md-table-of-contents-icon")!
    }
    
    var selectedIcon: NSImage {
        return NSImage(named: "md-table-of-contents-selected-icon")!
    }
    
    var databaseManager: DatabaseManager!
    var searchService: BRSearchService!
    
    // MARK: - Custom Properties
    
    var template: String?
    
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
    
    dynamic var tableOfContentsAnchor = ""
        
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
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
