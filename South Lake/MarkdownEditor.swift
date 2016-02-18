//
//  MarkdownEditor.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import WebKit

class MarkdownEditor: NSViewController {
    @IBOutlet var splitView: MPDocumentSplitView!
    @IBOutlet var editorContainer: NSView!
    @IBOutlet var editor: MPEditorView!
    @IBOutlet var preview: WebView!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
