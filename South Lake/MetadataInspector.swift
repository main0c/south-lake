//
//  MetadataInspector.swift
//  South Lake
//
//  Created by Philip Dow on 3/9/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

private let kTitle = "title"
private let kChildren = "children"
private let kIdentifier = "identifier"
private let kHeight = "height"
private let kHeaderCell = "HeaderCell"
private let kTagsCell = "TagsCell"

class MetadataInspector: NSViewController, Inspector {
    @IBOutlet var outlineView: NSOutlineView!
    
    // MARK: - Inspector

    var icon: NSImage {
        return NSImage(named: "metadata-icon")!
    }
    
     var selectedIcon: NSImage {
        return NSImage(named: "metadata-selected-icon")!
    }
    
    var databaseManager: DatabaseManager?
    var searchService: BRSearchService?
    
    // MARK: - Custom Properties
    
    // http://stackoverflow.com/questions/24828553/swift-code-to-use-nsoutlineview-as-file-system-directory-browser/27626466#27626466
    
    let items:[[String:AnyObject]] = [
        [
            kTitle: NSLocalizedString("File Info", comment:""),
            kIdentifier: "FileInfoCell",
            kHeight: CGFloat(116),
            kChildren: []
        ],
        [
            kTitle: NSLocalizedString("Tags", comment:""),
            kIdentifier: "TagsCell",
            kHeight: CGFloat(116),
            kChildren: []
        ]
    ]
    
    // MARK: - Initialization
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // outlineView.usesStaticContents = true // what effect?
        outlineView.selectionHighlightStyle = .None
        outlineView.backgroundColor = UI.Color.InspectorBackground
        
        outlineView.sizeLastColumnToFit()
        outlineView.expandItem(nil, expandChildren: true)
    }
    
    func willClose() {
    
    }
}

// MARK: - NSOutlineViewDataSource

extension MetadataInspector: NSOutlineViewDataSource {
    
    func outlineView(outlineView: NSOutlineView, numberOfChildrenOfItem item: AnyObject?) -> Int {
        guard let item = item as? [NSString: AnyObject] else {
            return items.count
        }
        return item[kChildren]!.count
    }
    
    func outlineView(outlineView: NSOutlineView, child index: Int, ofItem item: AnyObject?) -> AnyObject {
        guard let item = item as? [NSString: AnyObject] else {
            return items[index]
        }
        return item[kChildren]![index]
    }
    
    func outlineView(outlineView: NSOutlineView, isItemExpandable item: AnyObject) -> Bool {
        guard let item = item as? [NSString: AnyObject] else {
            return true
        }
        return item[kChildren]!.count > 0
    }

}

// MARK: - NSOutlineViewDelegate

extension MetadataInspector: NSOutlineViewDelegate {
    
    func outlineView(outlineView: NSOutlineView, viewForTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> NSView? {
        guard let item = item as? [NSString: AnyObject] else {
            return nil //error
        }
        
        let identifier = item[kIdentifier] as! String
        let view = outlineView.makeViewWithIdentifier(identifier, owner: self) as! NSTableCellView
        
        if identifier == kHeaderCell {
            view.textField?.stringValue = item[kTitle] as! String
            view.textField?.textColor = NSColor(white:0.0, alpha:1.0)
        }
        if identifier == kTagsCell {
            if let tokenField = view.viewWithTag(42) as? NSTokenField {
                tokenField.backgroundColor = UI.Color.InspectorBackground
            }
        }
        
        return view
    }
    
    func outlineView(outlineView: NSOutlineView, isGroupItem item: AnyObject) -> Bool {
        guard let item = item as? [NSString: AnyObject] else {
            return false //error
        }
        
        let identifier = item[kIdentifier] as! String
        return identifier == kHeaderCell
    }
    
    func outlineView(outlineView: NSOutlineView, heightOfRowByItem item: AnyObject) -> CGFloat {
        guard let item = item as? [NSString: AnyObject] else {
            return 0 //error
        }
        
        let identifier = item[kIdentifier] as! String
        
        if identifier == kHeaderCell {
            return 17 //default
        } else {
            return item[kHeight] as! CGFloat
        }
    }
    
    func outlineView(outlineView: NSOutlineView, shouldSelectItem item: AnyObject) -> Bool {
        guard let item = item as? [NSString: AnyObject] else {
            return false
        }
        
        let identifier = item[kIdentifier] as! String
        return identifier != kHeaderCell
    }
    
    func outlineView(outlineView: NSOutlineView, shouldTrackCell cell: NSCell, forTableColumn tableColumn: NSTableColumn?, item: AnyObject) -> Bool {
        return true
    }
    
}
