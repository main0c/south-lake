//
//  NSTokenFieldTokenTracker.swift
//  South Lake
//
//  Created by Philip Dow on 3/13/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//
//  http://stackoverflow.com/questions/28395047/nstokenfield-not-firing-action
//  Hardly a perfect solution: if th content changes without the count changing,
//  for example because of a copy-paste operation when all the token field text
//  is selected, then an update won't occur and a double-return is still needed

import Cocoa

class NSTokenFieldTokenTracker: NSObject, NSControlTextEditingDelegate, NSTokenFieldDelegate {
    
    var tokenField: NSTokenField
    weak var layoutManager: NSLayoutManager?
    var tokenCount: Int = -1
    
    init(tokenField: NSTokenField, delegate: Bool) {
        self.tokenField = tokenField
        super.init()
        
        if (delegate) {
            self.tokenField.setDelegate(self)
        }
    }
    
    func control(control: NSControl, textShouldBeginEditing fieldEditor: NSText) -> Bool {
        guard fieldEditor is NSTextView else {
            return true
        }
        layoutManager = (fieldEditor as! NSTextView).layoutManager
        return true
    }
    
    override func controlTextDidChange(obj: NSNotification) {
        guard let layoutManager = layoutManager else {
            return
        }
        let count = numberOfAttachments(layoutManager.attributedString())
        if tokenCount != count {
            tokenCount = count
            tokenField.sendAction(tokenField.action, to: tokenField.target)
        }
    }
    
    func numberOfAttachments(attributedString: NSAttributedString) -> Int {
        let string = attributedString.string
        let attachments = Array(string.characters).filter {
            $0 == Character(UnicodeScalar(NSAttachmentCharacter))
        }
        return attachments.count
    }
}