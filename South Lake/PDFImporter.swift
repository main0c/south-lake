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
    
    func plainTextRepresentation(data: NSData?) -> String {
        guard let data = data else {
            return ""
        }
        guard let document = PDFDocument(data: data) else {
            print("unable to derive pdf from data")
            return ""
        }
        
        return document.string()
    }
}