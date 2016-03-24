//
//  FileTableView.swift
//  South Lake
//
//  Created by Philip Dow on 3/21/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa

class FileTableView: NSTableView {

    override func deleteBackward(sender: AnyObject?) {
        nextResponder?.tryToPerform(Selector("deleteBackward:"), with: sender)
    }
    
    override func insertNewline(sender: AnyObject?) {
        nextResponder?.tryToPerform(Selector("insertNewline:"), with: sender)
    }
    
    override func quickLookPreviewItems(sender: AnyObject?) {
        nextResponder?.tryToPerform(Selector("quickLookPreviewItems:"), with: sender)
    }

    override func keyDown(theEvent: NSEvent) {
        switch theEvent.charactersIgnoringModifiers {
        case .Some(String(Character(UnicodeScalar(NSDeleteCharacter)))):
            deleteBackward(nil)
        case .Some(String(Character(UnicodeScalar(NSCarriageReturnCharacter)))),
             .Some(String(Character(UnicodeScalar(NSNewlineCharacter)))),
             .Some(String(Character(UnicodeScalar(NSEnterCharacter)))):
            insertNewline(nil)
        case .Some(String(Character(UnicodeScalar(" ")))):
            quickLookPreviewItems(nil)
        default:
            super.keyDown(theEvent)
        }
    }

}
