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
    var modelName: String
    
    var outline: Outline
    var fileContents = ""
    
    init( model: String, module: String, outline: Outline ) {
        
        self.model = model
        self.module = module
        self.outline = outline
        self.modelName = ""
    }
    
    func buildModelFile() {
        
        startMainClassEntry()
        
        for index in 0..<outline.children.count {
            let thisModel = outline.children[index]
            addSimpleProperty( thisModel.key, type: thisModel.value )
        }
        
        makeInits()
        
        finishMainClassEntry()
        
        makeDecodable()
        makeEncodable()
    }
    
    func startMainClassEntry() {

        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US")
        dateFormatter.setLocalizedDateFormatFromTemplate("YYYY") // set template after setting locale
        let cpywrtDate = dateFormatter.string( from: Date() )
        
        dateFormatter.setLocalizedDateFormatFromTemplate("MM/dd/YYYY")
        let createdDate = dateFormatter.string( from: Date() )

        modelName = capitalizeName( model )
        
        let name = "Bill"

        let headerFormat = "//\n//\t\(modelName).swift\n//\t\(module)\n//\n"
        let creditFormat = "//\tCreated by \(name) on \(createdDate)\n"
        let cpywrtFormat = "//\tCopyright (c) \(cpywrtDate) Hilton Worldwide Inc. All rights reserved.\n"
        let importFormat = "//\n\nimport Foundation\nimport HiltonSharedUtilities\n\n"
        
        let classFormat  = "@objc public final class \(modelName): NSObject {\n\n"
        
        fileContents = headerFormat + creditFormat + cpywrtFormat + importFormat + classFormat
        
        // Fill in data
        
    }
    
    func addSimpleProperty( _ value: String, type: String ) {
        
        let simpleVarFormat = "\tpublic var \(unCapitalizeName( value )): \(type)\n"
        fileContents += simpleVarFormat
        
    }
    
    func makeInits( ) {
        
        fileContents += "\n\tinit( "
        
        for index in 0..<outline.children.count {
            let thisModel = outline.children[index]
            
            fileContents += paramName( thisModel.key, type: thisModel.value )
            if index < outline.children.count-1 {
                fileContents += ", "
            }
        }
        
        fileContents += " ) {\n\n"
        
        for index in 0..<outline.children.count {
            let thisModel = outline.children[index]
            
            fileContents += initName( thisModel.key )
        }
        
        
        fileContents += "\n\t}\n"
    }
    
    func finishMainClassEntry() {
        
        let footerFormat = "\n}\n"
        
        fileContents += footerFormat
    }
    
    func makeDecodable( ) {
        
        fileContents += "\n\nextension \(modelName): JSONDecodable {\n"
        fileContents += "\n\tpublic static func decode(_ json: JSON) throws -> \(modelName) {\n"
        
        //        for index in 0..<outline.children.count {
        //            let thisModel = outline.children[index]
        //
        //            fileContents += paramName( thisModel.key, type: thisModel.value )
        //            if index < outline.children.count-1 {
        //                fileContents += ", "
        //            }
        //        }
        //
        //        fileContents += " ) {\n\n"
        //
        //        for index in 0..<outline.children.count {
        //            let thisModel = outline.children[index]
        //
        //            fileContents += initName( thisModel.key )
        //        }
        
        fileContents += "\t}\n\n}\n\n"
    }
    
    func makeEncodable( ) {
        
        fileContents += "\n\nextension \(modelName): JSONEncodable {\n"
        fileContents += "\n\tpublic static func encode(_ json: JSON) throws -> \(modelName) {\n"
        
        //        for index in 0..<outline.children.count {
        //            let thisModel = outline.children[index]
        //
        //            fileContents += paramName( thisModel.key, type: thisModel.value )
        //            if index < outline.children.count-1 {
        //                fileContents += ", "
        //            }
        //        }
        //
        //        fileContents += " ) {\n\n"
        //
        //        for index in 0..<outline.children.count {
        //            let thisModel = outline.children[index]
        //
        //            fileContents += initName( thisModel.key )
        //        }
        
        fileContents += "\t}\n\n}\n\n"
    }
    
    
//--    ----    ----    ----    ----    ----    ----    ----
    
    
    func paramName( _ name: String, type: String ) -> String {
        
        return "\(unCapitalizeName( name )): \(type)"
    }
    
    func initName( _ name: String ) -> String {
        
        return "\t\tself.\(unCapitalizeName( name )) = \(unCapitalizeName( name ))\n"
    }
    
    func typeToString( _ type: EntryType ) -> String {
        
        return type.rawValue
    }
    
    func capitalizeName( _ name: String ) -> String {
        
        var newName = name
        var ch = newName.remove(at: newName.startIndex)
        ch = Character( String( ch ).uppercased() )
        newName.insert( ch, at: newName.startIndex )
        
        return newName
    }
    
    func unCapitalizeName( _ name: String ) -> String {
        
        var newName = name
        var ch = newName.remove(at: newName.startIndex)
        ch = Character( String( ch ).lowercased() )
        newName.insert( ch, at: newName.startIndex )
        
        return newName
    }
    
    // File actions
    func saveFile() {
        
        
    }
    
}
