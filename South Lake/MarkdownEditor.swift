//
//  MarkdownEditor.swift
//  South Lake
//
//  Created by Philip Dow on 2/17/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import WebKit

extension WebView {
    var mainFrameEnclosingScrollView: NSScrollView? {
        return mainFrame.frameView.documentView.enclosingScrollView
        // enclosingScrollView
    }
}

private var MarkdownEditorContext = 0

class MarkdownEditor: NSViewController {
    @IBOutlet var splitView: MPDocumentSplitView!
    @IBOutlet var editorContainer: NSView!
    @IBOutlet var editor: MPEditorView!
    @IBOutlet var preview: WebView!
    
    let MPEditorKeysToObserve: [String: Bool] = [
        "automaticDashSubstitutionEnabled": false,
        "automaticDataDetectionEnabled": false,
        "automaticQuoteSubstitutionEnabled": false,
        "automaticSpellingCorrectionEnabled": false,
        "automaticTextReplacementEnabled": false,
        "continuousSpellCheckingEnabled": false,
        "enabledTextCheckingTypes": false,
        "grammarCheckingEnabled": false
    ]
    
    var preferences: MPPreferences = MPPreferences.sharedInstance()
    var highlighter: HGMarkdownHighlighter!
    var renderer: MPRenderer!
    
    var initialContents: String?
    var lastPreviewScrollTop: CGFloat = 0.0
    var shouldHandleBoundsChange: Bool = true
    var printing: Bool = false
    var copying: Bool = false
    
    var previewVisible: Bool {
        return preview.frame.size.width != 0.0
    }
    
    var editorVisible: Bool {
        return editorContainer.frame.size.width != 0.0
    }
    
    var needsHTML: Bool {
        if preferences.markdownManualRender {
            return false
        } else {
            return self.previewVisible || self.preferences.editorShowWordCount
        }
    }
    
    // TEMPORARY
    
    dynamic var toc: String = ""
    dynamic var tocRef: String = "" {
        didSet {
            let script = "window.location.href = \"#" + tocRef + "\""
            let eval = preview.stringByEvaluatingJavaScriptFromString(script)
            print("\(tocRef) : \(eval)")
//            let URL = NSURL(string: "#" + tocRef)
//            preview.mainFrame.loadRequest(NSURLRequest(URL: URL!))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        // Default preferences
        
        preferences.editorBaseFont = NSFont(name: "Helvetica", size: 13.0)
        preferences.editorStyleName = "Tomorrow+"
        preferences.editorSyncScrolling = true
        
        preferences.htmlMathJax = true
        preferences.htmlMathJaxInlineDollar = false
        preferences.htmlSyntaxHighlighting = true
        preferences.htmlLineNumbers = true
        preferences.htmlHighlightingThemeName = ""
        preferences.htmlRendersTOC = true
        
        preferences.editorHorizontalInset = 10
        preferences.editorVerticalInset = 10
        
        // MacDown Code
        
        highlighter = HGMarkdownHighlighter(textView: editor, waitInterval: 0.1)
        
        renderer = MPRenderer()
        renderer.rendererFlags = preferences.rendererFlags()
        renderer.dataSource = self
        renderer.delegate = self

//        for (NSString *key in MPEditorPreferencesToObserve())
//        {
//            [defaults addObserver:self forKeyPath:key
//                          options:NSKeyValueObservingOptionNew context:NULL];
//        }
        
        for (key, _) in  MPEditorKeysToObserve {
            editor.addObserver(self, forKeyPath: key, options: .New, context: &MarkdownEditorContext)
        }

        editor.postsFrameChangedNotifications = true;
        preview.frameLoadDelegate = self;
        preview.policyDelegate = self;
        preview.editingDelegate = self;

        let center = NSNotificationCenter.defaultCenter()

        center.addObserver(self, selector: Selector("editorTextDidChange:"), name: NSTextDidChangeNotification, object: editor)
        
        center.addObserver(self, selector: Selector("userDefaultsDidChange:"), name: NSUserDefaultsDidChangeNotification, object: NSUserDefaults.standardUserDefaults())
        
        center.addObserver(self, selector: Selector("editorBoundsDidChange:"), name: NSViewBoundsDidChangeNotification, object: editor.enclosingScrollView?.contentView)
        
        center.addObserver(self, selector: Selector("editorFrameDidChange:"), name: NSViewFrameDidChangeNotification, object: editor)
        
//        center.addObserver(self, selector: Selector("didRequestEditorReload"), name: MPDidRequestEditorSetupNotification, object: nil)
//    
//        center.addObserver(self, selector: Selector("didRequestPreviewReload"), name: MPDidRequestPreviewRenderNotification, object: nil)
     
        
        if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber10_9)
        {
            center.addObserver(self, selector: Selector("previewDidLiveScroll:"), name: NSScrollViewDidEndLiveScrollNotification, object: preview.mainFrameEnclosingScrollView)
        }
        
        NSOperationQueue.mainQueue().addOperationWithBlock { () -> Void in
            self.setupEditor(nil)
            self.redrawDivider()

            if let loadedString = self.initialContents {
                self.editor.string = loadedString
                self.initialContents = nil
                
                self.renderer.parseAndRenderNow()
                self.highlighter.parseAndHighlightNow()
                
                self.toc = self.renderer.tableOfContents()
            }
        }
        
        // Load test.md
        
        do {
            let path = NSBundle.mainBundle().pathForResource("Test", ofType: "md")!
            let testMD = try NSString(contentsOfFile: path, encoding: NSUTF8StringEncoding) as String
            initialContents = testMD
        } catch {
            NSLog("Unable to read Test.md")
        }
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Functions
    
    func adjustEditorInsets() {
        var x = preferences.editorHorizontalInset
        let y = preferences.editorVerticalInset
        
        if preferences.editorWidthLimited {
            let editorWidth = editor.frame.size.width
            let maxWidth = preferences.editorMaximumWidth
            
            // We tend to expect things in an editor to shift to left a bit. Hence the 0.45 instead of 0.5 (which whould feel a bit too much).
            
            if editorWidth > 2 * x + maxWidth {
                x = (editorWidth - maxWidth) * 0.45
            }
        }
        
        editor.textContainerInset = NSSize(width: x, height: y)
    }
    
    func syncScrollers() {
        guard let previewScrollView = preview.mainFrameEnclosingScrollView,
                  previewDocumentView = previewScrollView.documentView else {
            return
        }
        
        let contentBounds = editor.enclosingScrollView!.contentView.bounds
        let realContentRect: NSRect = editor.contentRect()
        var ratio: CGFloat = 0.0
        
        if realContentRect.size.height > contentBounds.size.height {
            ratio = contentBounds.origin.y /
                (realContentRect.size.height - contentBounds.size.height)
        }

        let previewContentView = previewScrollView.contentView
        var previewContentBounds = previewContentView.bounds
        
        previewContentBounds.origin.y =
            ratio * (previewDocumentView.frame.size.height
                     - previewContentBounds.size.height)
        
        previewContentView.bounds = previewContentBounds
    }
    
    func render() {
        renderer.parseAndRenderLater()
    }
    
    func redrawDivider() {
    
    }
    
    func scaleWebview() {
    
    }
    
    func updateWordCount() {
    
    }
    
    func setupEditor(changedKey: String?) {
        highlighter.deactivate()
        
        if changedKey == nil || changedKey == "extensionFootnotes" {
        
        }
        
        if changedKey == nil
            || changedKey == "editorHorizontalInset"
            || changedKey == "editorVerticalInset"
            || changedKey == "editorWidthLimited"
            || changedKey == "editorMaximumWidth"
            {
            
            adjustEditorInsets()
        }
        
        if changedKey == nil
            || changedKey == "editorBaseFontInfo"
            || changedKey == "editorStyleName"
            || changedKey == "editorLineSpacing" {
            
            let style = NSMutableParagraphStyle()
            style.lineSpacing = preferences.editorLineSpacing
            editor.defaultParagraphStyle = style.copy() as? NSParagraphStyle
            
            let font = preferences.editorBaseFont.copy() as? NSFont
            editor.font = font
            
            editor.textColor = nil
            editor.backgroundColor = NSColor.clearColor()
            
            highlighter.styles = nil
            highlighter.readClearTextStylesFromTextView()
            
            let themeName = self.preferences.editorStyleName.copy() as? String
            
            if themeName != nil {
                let path = MPThemePathForName(themeName)
                let themeString = MPReadFileOfPath(path)
                
                highlighter.applyStylesFromStylesheet(themeString, withErrorHandler: { (_: [AnyObject]!) -> Void in
                    self.preferences.editorStyleName = nil
                })
            }
            
            let layer = CALayer()
            layer.backgroundColor = editor.backgroundColor.CGColor
            editorContainer.layer = layer
        }
        
        if changedKey == "editorBaseFontInfo" {
            scaleWebview()
        }
        
        if changedKey == nil || changedKey == "editorShowWordCount" {
        
        }
        
        if changedKey == nil || changedKey == "editorScrollsPastEnd" {
        
        }
        
        if changedKey == nil {
        
        }
        
        if changedKey == nil || changedKey == "editorOnRight" {
        
        }
        
        highlighter.activate()
        editor.automaticLinkDetectionEnabled = false
    }
    
    // MARK: - Notification handler

    func editorTextDidChange(notification: NSNotification) {
        if needsHTML {
            renderer.parseAndRenderLater() // why not render()
            
            toc = self.renderer.tableOfContents()
        }
    }

    func userDefaultsDidChange(notification: NSNotification) {
        // TODO
    }
   
    func editorFrameDidChange(notification: NSNotification) {
        if preferences.editorWidthLimited {
            adjustEditorInsets()
        }
    }

    func editorBoundsDidChange(notification: NSNotification) {
        if !shouldHandleBoundsChange {
            return
        }
        
        if preferences.editorSyncScrolling {
            objc_sync_enter(self)
            shouldHandleBoundsChange = false
            syncScrollers()
            shouldHandleBoundsChange = true
            objc_sync_exit(self)
        }
    }

    func didRequestEditorReload(notification: NSNotification) {
        // TODO
    }
   
    func didRequestPreviewReload(notification: NSNotification) {
        render()
    }
    
    func previewDidLiveScroll(notification: NSNotification) {
        guard let contentView = preview.mainFrameEnclosingScrollView?.contentView else {
            return
        }
        
        lastPreviewScrollTop = contentView.bounds.origin.y
    }
    
    // MARK: - KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        
        switch object {
        case _ as MPEditorView:
            if !highlighter.isActive {
                return
            }
            // TODO
        case _ as NSUserDefaults:
            if highlighter.isActive {
                setupEditor(keyPath!)
            }
            redrawDivider()
        default:
            break
        }
    }
    
}

// MARK: - WebFrameLoadDelegate

extension MarkdownEditor: WebFrameLoadDelegate {
    
    var previewLoadingCompletionHandler: (() -> Void) {
        get {
            func handler() {
                print("previewLoadingCompletionHandler")
                
                // FIXME: causes intermittent problems?, but needed to prevent flickering?
                
                if let window = preview.window {
                    objc_sync_enter(window)
                    if window.flushWindowDisabled {
                        print("enabling flush")
                        window.enableFlushWindow()
                    }
                    objc_sync_exit(window)
                }
                
                scaleWebview()
                
                if preferences.editorSyncScrolling {
                    syncScrollers()
                } else {
                    let contentView = preview.mainFrameEnclosingScrollView!.contentView
                    var bounds = contentView.bounds
                    
                    bounds.origin.y = lastPreviewScrollTop
                    contentView.bounds = bounds
                }
            }
            return handler
        }
    }
    
    func webView(sender: WebView!, didCommitLoadForFrame frame: WebFrame!) {
        print("didCommitLoadForFrame")
        
        guard sender.windowScriptObject as WebScriptObject? != nil else {
            print("window script object is nil")
            return
        }
        
        // FIXME: causes intermittent problems?, but needed to prevent flickering?
        
        if let window = sender.window {
            objc_sync_enter(window)
            if !window.flushWindowDisabled {
                print("disabling flush")
                window.disableFlushWindow()
            }
            objc_sync_exit(window)
        }
        
        // If MathJax is off, the on-completion callback will be invoked directly when loading is done (in -webView:didFinishLoadForFrame:).
        
        if preferences.htmlMathJax {
            
            let listener = MPMathJaxListener()
            listener.addCallback(previewLoadingCompletionHandler, forKey: "End")
            sender.windowScriptObject.setValue(listener, forKey: "MathJaxListener")
        }
    }
    
    func webView(sender: WebView!, didFinishLoadForFrame frame: WebFrame!) {
        print("didFinishLoadForFrame")
        
        // If MathJax is on, the on-completion callback will be invoked by the JavaScript handler injected in -webView:didCommitLoadForFrame:.
        
        if !preferences.htmlMathJax {
            let callback = previewLoadingCompletionHandler
            let queue = NSOperationQueue.mainQueue()
            queue.addOperationWithBlock(callback)
        }
        
        // self.previewReady = true
        
        if preferences.editorShowWordCount {
            updateWordCount()
        }
    }
    
    func webView(sender: WebView!, didFailLoadWithError error: NSError!, forFrame frame: WebFrame!) {
        
        webView(sender, didFinishLoadForFrame: frame)
    }
}

// MARK: - WebPolicyDelegate

extension MarkdownEditor: WebPolicyDelegate {

}

// MARK: - WebEditingDelegate

extension MarkdownEditor: WebEditingDelegate {
    
    override func webView(webView: WebView!, doCommandBySelector selector: Selector) -> Bool {
        if selector == Selector("copy:") {
            let html = webView.selectedDOMRange.markupString
            NSOperationQueue.mainQueue().addOperationWithBlock({ () -> Void in
                let pb = NSPasteboard.generalPasteboard()
                if pb.stringForType("public.html") == nil {
                    pb.setString(html, forType: "public.html")
                }
            })
        }
        return false
    }
}

// MARK: - WebUIDelegate

extension MarkdownEditor: WebUIDelegate {
    
    func webView(webView: WebView!, dragDestinationActionMaskForDraggingInfo draggingInfo: NSDraggingInfo!) -> Int {
        return Int(WebDragDestinationAction.None.rawValue)
    }
}

// MARK: - MPRendererDataSource

extension MarkdownEditor: MPRendererDataSource {

    func rendererMarkdown(renderer: MPRenderer!) -> String! {
        return editor.string
    }

    func rendererHTMLTitle(renderer: MPRenderer!) -> String! {
        return "Title"
    }

}

// MARK: - MPRendererDelegate

extension MarkdownEditor: MPRendererDelegate {
    
    func rendererExtensions(renderer: MPRenderer!) -> Int32 {
        return preferences.extensionFlags()
    }
    
    func rendererHasSmartyPants(renderer: MPRenderer!) -> Bool {
        return preferences.extensionSmartyPants
    }
    
    func rendererRendersTOC(renderer: MPRenderer!) -> Bool {
        return preferences.htmlRendersTOC
    }
    
    func rendererStyleName(renderer: MPRenderer!) -> String! {
        return preferences.htmlStyleName
    }
    
    func rendererDetectsFrontMatter(renderer: MPRenderer!) -> Bool {
        return preferences.htmlDetectFrontMatter
    }
    
    func rendererHasSyntaxHighlighting(renderer: MPRenderer!) -> Bool {
        return preferences.htmlSyntaxHighlighting;
    }
    
    func rendererCodeBlockAccesory(renderer: MPRenderer!) -> MPCodeBlockAccessoryType {
        return MPCodeBlockAccessoryType.None
        //return preferences.htmlCodeBlockAccessory
    }
    
    func rendererHasMathJax(renderer: MPRenderer!) -> Bool {
        return preferences.htmlMathJax;
    }
    
    func rendererHighlightingThemeName(renderer: MPRenderer!) -> String! {
        return preferences.htmlHighlightingThemeName;
    }
    
    func renderer(renderer: MPRenderer!, didProduceHTMLOutput html: String!) {
        
        if printing {
            return
        }

        // Delayed copying for -copyHtml.
        if (copying) {
            copying = false
            
            NSPasteboard.generalPasteboard().clearContents()
            NSPasteboard.generalPasteboard().writeObjects([renderer.currentHtml()])
        }
        

        let baseURL = NSBundle.mainBundle().bundleURL
        preview.mainFrame.loadHTMLString(html, baseURL: baseURL)

        // NSURL *baseUrl = self.fileURL;
        // if (!baseUrl)   // Unsaved doument; just use the default URL.baseUrl = self.preferences.htmlDefaultDirectoryUrl;
        // [self.preview.mainFrame loadHTMLString:html baseURL:baseUrl];
        // self.manualRender = self.preferences.markdownManualRender;
        //self.currentBaseUrl = baseUrl;
    }
}


// MARK: - HoedownExtensions

struct HoedownExtensions: OptionSetType {
    let rawValue: Int
    init(rawValue: Int) { self.rawValue = rawValue }
    
    static let NONE =                                   HoedownExtensions(rawValue: 0)
    
    /* block-level extensions */
    static let HOEDOWN_EXT_TABLES =                     HoedownExtensions(rawValue: 1 << 0)
    static let HOEDOWN_EXT_FENCED_CODE =                HoedownExtensions(rawValue: 1 << 1)
    static let HOEDOWN_EXT_FOOTNOTES =                  HoedownExtensions(rawValue: 1 << 2)
    
    /* span-level extensions */
    static let HOEDOWN_EXT_AUTOLINK =                   HoedownExtensions(rawValue: 1 << 3)
    static let HOEDOWN_EXT_STRIKETHROUGH =              HoedownExtensions(rawValue: 1 << 4)
    static let HOEDOWN_EXT_UNDERLINE =                  HoedownExtensions(rawValue: 1 << 5)
    static let HOEDOWN_EXT_HIGHLIGHT =                  HoedownExtensions(rawValue: 1 << 6)
    static let HOEDOWN_EXT_QUOTE =                      HoedownExtensions(rawValue: 1 << 7)
    static let HOEDOWN_EXT_SUPERSCRIPT =                HoedownExtensions(rawValue: 1 << 8)
    static let HOEDOWN_EXT_MATH =                       HoedownExtensions(rawValue: 1 << 9)
    
    // skip 1 << 10
    
    /* other flags */
    static let HOEDOWN_EXT_NO_INTRA_EMPHASIS =          HoedownExtensions(rawValue: 1 << 11)
    static let HOEDOWN_EXT_SPACE_HEADERS =              HoedownExtensions(rawValue: 1 << 12)
    static let HOEDOWN_EXT_MATH_EXPLICIT =              HoedownExtensions(rawValue: 1 << 13)
    
    /* negative flags */
    static let HOEDOWN_EXT_DISABLE_INDENTED_CODE =      HoedownExtensions(rawValue: 1 << 14)
    
    /* additional extensions */
    static let HOEDOWN_HTML_USE_TASK_LIST =             HoedownExtensions(rawValue: 1 << 4)
    static let HOEDOWN_HTML_BLOCKCODE_LINE_NUMBERS =    HoedownExtensions(rawValue: 1 << 5)
    static let HOEDOWN_HTML_BLOCKCODE_INFORMATION =     HoedownExtensions(rawValue: 1 << 6)
    
    static let HOEDOWN_HTML_SKIP_HTML =                 HoedownExtensions(rawValue: 1 << 0)
    static let HOEDOWN_HTML_ESCAPE =                    HoedownExtensions(rawValue: 1 << 1)
    static let HOEDOWN_HTML_HARD_WRAP =                 HoedownExtensions(rawValue: 1 << 2)
    static let HOEDOWN_HTML_USE_XHTML =                 HoedownExtensions(rawValue: 1 << 3)
}

// MARK: - MPPreferences

extension MPPreferences {
    func extensionFlags() -> Int32 {
        var flags: HoedownExtensions = []
        if (extensionAutolink) {
            flags.insert(.HOEDOWN_EXT_AUTOLINK)
        }
        if (extensionFencedCode) {
            flags.insert(.HOEDOWN_EXT_FENCED_CODE)
        }
        if (extensionFootnotes) {
            flags.insert(.HOEDOWN_EXT_FOOTNOTES)
        }
        if (extensionHighlight) {
            flags.insert(.HOEDOWN_EXT_HIGHLIGHT)
        }
        if (!extensionIntraEmphasis) {
            flags.insert(.HOEDOWN_EXT_NO_INTRA_EMPHASIS)
        }
        if (extensionQuote) {
            flags.insert(.HOEDOWN_EXT_QUOTE)
        }
        if (extensionStrikethough) {
            flags.insert(.HOEDOWN_EXT_STRIKETHROUGH)
        }
        if (extensionSuperscript) {
            flags.insert(.HOEDOWN_EXT_SUPERSCRIPT)
        }
        if (extensionTables) {
            flags.insert(.HOEDOWN_EXT_TABLES)
        }
        if (extensionUnderline) {
            flags.insert(.HOEDOWN_EXT_UNDERLINE)
        }
        if (htmlMathJax) {
            flags.insert(.HOEDOWN_EXT_MATH)
        }
        if (htmlMathJaxInlineDollar) {
            flags.insert(.HOEDOWN_EXT_MATH_EXPLICIT)
        }
        return Int32(flags.rawValue);
    }

    func rendererFlags() -> Int32 {
        var flags: HoedownExtensions = []
        
        if (htmlTaskList) {
            flags.insert(.HOEDOWN_HTML_USE_TASK_LIST)
        }
        if (htmlLineNumbers) {
            flags.insert(.HOEDOWN_HTML_BLOCKCODE_LINE_NUMBERS)
        }
        if (self.htmlHardWrap) {
            flags.insert(.HOEDOWN_HTML_HARD_WRAP)
        }
//        if (self.htmlCodeBlockAccessory == MPCodeBlockAccessoryCustom) {
//            flags.insert(.HOEDOWN_HTML_BLOCKCODE_INFORMATION)
//        }
        
        return Int32(flags.rawValue);
    }
}
