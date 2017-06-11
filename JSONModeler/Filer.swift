//
//  Filer.swift
//  JSONModeler
//
//  Created by William Snook on 6/11/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation


class Filer {
    
    let model: String
    let module: String
    
    var fileContents = ""
    
    init( model: String, module: String ) {
        
        self.model = model
        self.module = module
    }
    
    func startFileEntry() {
    
        let headerFormat = "//\n//  \(model).swift\n//  \(module)\n//\n\nimport Foundation\nimport HiltonSharedUtilities\n\n"
        
        let classFormat = "@@objc public final class \(model): NSObject {\n\n"
        
        fileContents = headerFormat + classFormat
        
        // Fill in data
        
    }
    
    func finishFileEntry() {
    
        let footerFormat = "\n}\n"
        
        fileContents += footerFormat
    }
}
