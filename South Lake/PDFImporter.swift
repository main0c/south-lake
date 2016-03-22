//
//  PDFImporter.swift
//  South Lake
//
//  Created by Philip Dow on 3/8/16.
//  Copyright © 2016 Phil Dow. All rights reserved.
//

import Cocoa
import Quartz

@objc(PDFImporter)
class PDFImporter: NSObject, FileImporter {
    static var filetypes: [String] = ["com.adobe.pdf", "pdf", "application/pdf"]
    
    override required init() {
        super.init()
    }
    
    func plainTextRepresentation(data: NSData?) -> String? {
        guard let data = data else {
            return nil
        }
        guard let document = PDFDocument(data: data) else {
            print("unable to derive pdf from data")
            return nil
        }
        
        let badCharacters = NSMutableCharacterSet.alphanumericCharacterSet()
            .union(NSCharacterSet.whitespaceAndNewlineCharacterSet())
            .union(NSCharacterSet.punctuationCharacterSet())
            .invertedSet
        
        let text = document
            .string()
            .componentsSeparatedByCharactersInSet(badCharacters)
            .filter { !$0.isEmpty }
            .joinWithSeparator(" ")
        
        return text
    }
    
    func thumbnail(data: NSData?) -> NSImage? {
        return nil
    }
}