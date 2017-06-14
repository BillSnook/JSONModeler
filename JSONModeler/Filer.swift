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
    
    var outline: Outline
    var fileContents = ""
    
    init( model: String, module: String, outline: Outline ) {
        
        self.model = model
        self.module = module
        self.outline = outline
    }
    
    func buildModelFile() -> String {
        
        startFileEntry()
        
        for index in 0..<outline.children.count {
            let thisModel = outline.children[index]
            switch thisModel.childType {
            case .string:
                addSimpleProperty( thisModel.key )
            case .dictionary:
                addDictionaryProperty( thisModel.key )
            case .array:
                addArrayProperty( thisModel.key )
            default:
                addSimpleProperty( "?" )
            }
        }
        
        makeInits()
        
        finishFileEntry()

        return fileContents
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
    
    func makeInits( ) {
        
        fileContents += "\n    init( "
        
        for index in 0..<outline.children.count {
            let thisModel = outline.children[index]
            
            fileContents += paramName( thisModel.key, type: thisModel.childType.rawValue )
            if index < outline.children.count-1 {
                fileContents += ", "
            }
        }
        
        fileContents += " ) {\n\n"
        
        
        fileContents += "\n    }\n\n"
    }
    
    func paramName( _ name: String, type: String ) -> String {
        
        return "\(name): \(type)"
    }
    
    func typeToString( _ type: EntryType ) -> String {
        
        return type.rawValue
    }
    
    func finishFileEntry() {
    
        let footerFormat = "\n}\n"
        
        fileContents += footerFormat
    }
}
