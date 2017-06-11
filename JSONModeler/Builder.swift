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
    
    let objectRoot: AnyObject
    var indent = 0
    
    init( _ jsonObject: AnyObject ) {
        
        objectRoot = jsonObject
    }
    
    func buildModelFile() -> Bool {
    
        let objDictionary = objectRoot as? DictionaryType
        if objDictionary != nil {
            print( "" )
            return modelDictionary( objDictionary! )
        } else {
            let objArray = objectRoot as? ArrayType
            if objArray != nil {
                print( "" )
                return modelArray( objArray! )
            } else {
                print( "Error, top=level object is neither a dictionary or an array" )
                return false
            }
        }
    }
    
    func modelDictionary( _ dictionary: DictionaryType ) -> Bool {
    
        let keys = dictionary.keys
        var didSucceed = true
        
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
                didSucceed = modelDictionary( objDictionary! )
            } else {
                let objArray = value as? ArrayType
                if objArray != nil {
                    didSucceed = modelArray( objArray! )
                } else {
                    indent += 1
                    didSucceed = modelString( value as AnyObject )
                    indent -= 1
                }
            }
            if !didSucceed {
                print( "Failed for key \(key) with \(String(describing: value))" )
            }
        }
        indent -= 1
        return didSucceed
    }
    
    func modelArray( _ array: ArrayType ) -> Bool {
    
        var didSucceed = true
        
        indent += 1
        for entry in array {
            let objDictionary = entry as? DictionaryType
            if objDictionary != nil {
                didSucceed = modelDictionary( objDictionary! )
            } else {
                let objArray = entry as? ArrayType
                if objArray != nil {
                    didSucceed = modelArray( objArray! )
                } else {
                    didSucceed = modelString( entry as AnyObject )
                }
            }
            if !didSucceed {
                print( "Failed with \(String(describing: entry))" )
            }
        }
        indent -= 1
        return didSucceed
    }
    
    func modelString( _ object: AnyObject ) -> Bool {

        let newString = object as? String
        if newString != nil {
            var indentSpace = ""
            for _ in 1..<indent {
                indentSpace += "  "
            }
            print( "\(indentSpace)\(newString!)" )
            return true
        } else {
            print( "Got unrecognized type: \(String(describing: object))" )
            return false
        }
    }
}
