//
//  Builder.swift
//  JSONModeler
//
//  Created by William Snook on 6/10/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation

/*
 
Discussion: We have a dictionary or an array derived from a json string.
  We want to use that to create a series of JSONModel files
  representing the structures and relationships from the file.
    To do that, we walk the structures, intending to collect
  dictionary keys and value types and array types to publish.
    The intended output format is the JSONModel file.
 */

class Builder {
    
    let modelName: String
    let objectRoot: AnyObject
    
    var outlineRoot: Outline
    
    var indent = 0
    
    init( _ jsonObject: AnyObject, fileName: String ) {
        
        objectRoot = jsonObject     // This is a dictionary or an array that reflects the json file structure and contents
        modelName = fileName
        outlineRoot = Outline( key: modelName, value: "", type: .dictionary )
    }
    
    func buildModelFile() -> Outline? {
    
        let objDictionary = objectRoot as? DictionaryType
        if objDictionary != nil {
            print( "" )
            if let children = modelDictionary( objDictionary! ) {
                outlineRoot.addChildren( children )
                return outlineRoot
            } else {
                return nil
            }
        } else {
//            let objArray = objectRoot as? ArrayType
//            if objArray != nil {
//                print( "" )
//                return modelArray( objArray! )
//            } else {
                print( "Error, top-level object is neither a dictionary or an array" )
                return nil
//            }
        }
    }
    
    func modelDictionary( _ dictionary: DictionaryType ) -> [Outline]? {
    
        let keys = dictionary.keys
        var outline = [Outline]()
        
        indent += 1
        var indentSpace = ""
        for _ in 1..<indent {
            indentSpace += "  "
        }
        for key in keys {
            print( "\(indentSpace)\(key ) :" )
            let value = dictionary[key]
            
            let objDictionary = value as? DictionaryType
            if objDictionary != nil {
                let newOutline = Outline(key: key, value: "", type: .dictionary )
                if let children = modelDictionary( objDictionary! ) {
                    newOutline.addChildren( children )
                    outline.append( newOutline )
                } else {
                    return nil
                }
            } else {
//                let objArray = value as? ArrayType
//                if objArray != nil {
//                    let child = modelArray( objArray! )
//                    outline?.addChild( child )
//                } else {
                    indent += 1
                    if let value = modelString( value as AnyObject ) {
                        let child = Outline(key: key, value: value, type: .string )
                        outline.append( child )
                    } else {
                        return nil
                    }
                    indent -= 1
//                }
            }
//            if outline == nil {
//                print( "Failed for key \(key) with \(String(describing: value))" )
//            } else {
//                
//            }
        }
        indent -= 1
        return outline
    }
    
//    func modelArray( _ array: ArrayType ) -> [Outline]? {
//    
//        var outline: [Outline]?
//        
//        indent += 1
//        for entry in array {
//            let objDictionary = entry as? DictionaryType
//            if objDictionary != nil {
//                outline = modelDictionary( objDictionary! )
//            } else {
//                let objArray = entry as? ArrayType
//                if objArray != nil {
//                    outline = modelArray( objArray! )
//                } else {
//                    outline = modelString( entry as AnyObject )
//                }
//            }
//            if outline == nil {
//                print( "Failed with \(String(describing: entry))" )
//            }
//        }
//        indent -= 1
//        return outline
//    }
    
    func modelString( _ object: AnyObject ) -> String? {

//        var outline: Outline?

        let newString = object as? String
        if newString != nil {
            var indentSpace = ""
            for _ in 1..<indent {
                indentSpace += "  "
            }
            print( "\(indentSpace)\(newString!)" )
            return newString
        } else {
            let hopefulString = String(describing: object)
            print( "Got unrecognized type: \(hopefulString)" )
            return nil // hopefulString
        }
    }
}
