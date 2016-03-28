//
//  FileListCollectionView.swift
//  South Lake
//
//  Created by Philip Dow on 3/28/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Foundation

class FileListCollectionView: NSCollectionView {

    /// Because as far as I can tell the firstResponder property doesn't do shit
    
    dynamic var fr: Bool = false

    override func becomeFirstResponder() -> Bool {
        fr = true
        return super.becomeFirstResponder()
    }

    override func resignFirstResponder() -> Bool {
        fr = false
        return super.resignFirstResponder()
    }
    
    // MARK: - User key events
    // TODO: Unused?

//    override func deleteBackward(sender: AnyObject?) {
//        nextResponder?.tryToPerform(Selector("deleteBackward:"), with: sender)
//    }
//    
//    override func insertNewline(sender: AnyObject?) {
//        nextResponder?.tryToPerform(Selector("insertNewline:"), with: sender)
//    }
//    
//    override func quickLookPreviewItems(sender: AnyObject?) {
//        nextResponder?.tryToPerform(Selector("quickLookPreviewItems:"), with: sender)
//    }
//
//    override func keyDown(theEvent: NSEvent) {
//        switch theEvent.charactersIgnoringModifiers {
//        case .Some(String(Character(UnicodeScalar(NSDeleteCharacter)))):
//            deleteBackward(nil)
//        case .Some(String(Character(UnicodeScalar(NSCarriageReturnCharacter)))),
//             .Some(String(Character(UnicodeScalar(NSNewlineCharacter)))),
//             .Some(String(Character(UnicodeScalar(NSEnterCharacter)))):
//            insertNewline(nil)
//        case .Some(String(Character(UnicodeScalar(" ")))):
//            quickLookPreviewItems(nil)
//        default:
//            super.keyDown(theEvent)
//        }
//    }
    
}