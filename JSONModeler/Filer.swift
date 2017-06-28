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
            addSimpleProperty( thisModel.key, type: thisModel.childType.rawValue )
        }
        
        makeInits()
        
        finishFileEntry()

        return fileContents
    }
    
    func startFileEntry() {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY") // set template after setting locale
        let cpywrtDate = dateFormatter.string( from: Date() )
        
        dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd/YYYY")
        let createdDate = dateFormatter.string( from: Date() )

        let name = "Bill"
        let modelName = capitalizeName(name: model )

        let headerFormat = "//\n//\t\(modelName).swift\n//\t\(module)\n//\n"
        let creditFormat = "//\tCreated by \(name) on \(createdDate)\n"
        let cpywrtFormat = "//\tCopyright (c) \(cpywrtDate) Hilton Worldwide Inc. All rights reserved.\n"
        let importFormat = "//\n\nimport Foundation\nimport HiltonSharedUtilities\n\n"
        
        let classFormat  = "@objc public final class \(modelName): NSObject {\n\n"
        
        fileContents = headerFormat + creditFormat + cpywrtFormat + importFormat + classFormat
        
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
    
    func capitalizeName( name: String ) -> String {
        
        var newName = name
        var ch = newName.remove(at: newName.startIndex)
        ch = Character( String( ch ).uppercased() )
        newName.insert( ch, at: newName.startIndex )
        
        return newName
    }
}
