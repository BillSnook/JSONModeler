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
    
    func buildModelFile( _ outlines: Outline ) -> Bool {
        
        startFileEntry()
        
        for index in 0..<outlines.children.count {
            let outline = outlines.children[index]
            switch outline.childType {
            case .string:
                addSimpleProperty( outline.key )
            case .dictionary:
                addDictionaryProperty( outline.key )
            case .array:
                addArrayProperty( outline.key )
            default:
                addSimpleProperty( "?" )
            }
        }
        
        finishFileEntry()

        return true
    }
    
    func startFileEntry() {
    
        let headerFormat = "//\n//  \(model).swift\n//  \(module)\n//\n\nimport Foundation\nimport HiltonSharedUtilities\n\n"
        
        let classFormat = "@objc public final class \(model): NSObject {\n\n"
        
        fileContents = headerFormat + classFormat
        
        // Fill in data
        
    }
    
    func addSimpleProperty( _ value: String ) {
        
        let simpleVarFormat = "    public var \(value) : String\n"
        fileContents += simpleVarFormat
        
    }
    
    func addDictionaryProperty( _ value: String ) {
        
        let simpleVarFormat = "    public var \(value) : Dictionary\n"
        fileContents += simpleVarFormat
        
    }
    
    func addArrayProperty( _ value: String ) {
        
        let simpleVarFormat = "    public var \(value) : Array\n"
        fileContents += simpleVarFormat
        
    }
    
    func finishFileEntry() {
    
        let footerFormat = "\n}\n"
        
        fileContents += footerFormat
    }
}
