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
//            switch thisModel.childType {
//            case .string:
            addSimpleProperty( thisModel.key, type: thisModel.childType.rawValue )
//            case .dictionary:
//                addDictionaryProperty( thisModel.key )
//            case .array:
//                addArrayProperty( thisModel.key )
//            default:
//                addSimpleProperty( "?" )
//            }
        }
        
        makeInits()
        
        finishFileEntry()

        return fileContents
    }
    
    func startFileEntry() {
    
        let headerFormat = "//\n//\t\(model).swift\n//\t\(module)\n"
        let creditFormat = "//\n//\tCreated on \(Date())\tfor Hilton\n//"
        let importFormat = "\n\nimport Foundation\nimport HiltonSharedUtilities\n\n"
        
        let classFormat  = "@objc public final class \(model): NSObject {\n\n"
        
        fileContents = headerFormat + creditFormat + importFormat + classFormat
        
        // Fill in data
        
    }
    
    func addSimpleProperty( _ value: String, type: String ) {
        
        let simpleVarFormat = "\tpublic var \(value): \t\t\(type)\n"
        fileContents += simpleVarFormat
        
    }
    
    func makeInits( ) {
        
        fileContents += "\n\tinit( "
        
        for index in 0..<outline.children.count {
            let thisModel = outline.children[index]
            
            fileContents += paramName( thisModel.key, type: thisModel.childType.rawValue )
            if index < outline.children.count-1 {
                fileContents += ", "
            }
        }
        
        fileContents += " ) {\n\n"
        
        
        fileContents += "\n\t}\n\n"
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
