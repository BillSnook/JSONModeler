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
    
    
    init( _ jsonObject: AnyObject, fileName: String ) {
        
        objectRoot = jsonObject     // This is a dictionary or an array that reflects the json file structure and contents
        modelName = fileName
        outlineRoot = Outline( key: modelName, value: "", type: .dictionary )
    }
    
    func buildModelFile() -> Outline? {
    
        if let objDictionary = objectRoot as? DictionaryType {
            if let children = modelDictionary( objDictionary ) {
                outlineRoot.addChildren( children )
                return outlineRoot
            } else {
                return nil
            }
        } else {
            if let objArray = objectRoot as? ArrayType {
                if let children = modelArray( objArray, name: modelName ) {
                    outlineRoot.addChildren( children )
                    return outlineRoot
                } else {
                    return nil
                }
            } else {
                print( "Error, top-level object is neither a dictionary or an array" )
                return nil
            }
        }
    }
    
    func modelDictionary( _ dictionary: DictionaryType ) -> [Outline]? {
    
        let keys = dictionary.keys
        var outline = [Outline]()
        
        for key in keys {
            let value = dictionary[key]
            if let objDictionary = value as? DictionaryType {
                let newOutline = Outline(key: key, value: key + "Dictionary", type: .dictionary )
                if let children = modelDictionary( objDictionary ) {
                    newOutline.addChildren( children )
                    outline.append( newOutline )
                } else {
                    return nil
                }
            } else {
                if let objArray = value as? ArrayType {
                    let newOutline = Outline(key: key, value: key + "Array", type: .array )
                    if let children = modelArray( objArray, name: key ) {
                        newOutline.addChildren( children )
                        outline.append( newOutline )
                    } else {
                        return nil
                    }
                } else {
                    if let _ = modelString( value as AnyObject ) {
                        let newOutline = Outline(key: key, value: "String", type: .string )
                        outline.append( newOutline )
                    } else {
                        return nil
                    }
                }
            }
        }
        return outline
    }
    
    func modelArray( _ array: ArrayType, name: String ) -> [Outline]? {
    
        var outline = [Outline]()
        
        guard let entry = array.first else { return outline }
        
        var i = 0
        i += 1
        if let objDictionary = entry as? DictionaryType {
            let newOutline = Outline(key: name + "\(i)", value: name + "\(i)Dictionary", type: .dictionary )
            if let children = modelDictionary( objDictionary ) {
                newOutline.addChildren( children )
                outline.append( newOutline )
            } else {
                return nil
            }
        } else {
            if let objArray = entry as? ArrayType {
                let newOutline = Outline(key: name + "\(i)", value: name + "\(i)Array", type: .array )
                if let children = modelArray( objArray, name: name + "\(i)" ) {
                    newOutline.addChildren( children )
                    outline.append( newOutline )
                } else {
                    return nil
                }
            } else {
                if let value = modelString( entry as AnyObject ) {
                    let newOutline = Outline(key: value, value: "String", type: .string )
                    outline.append( newOutline )
                } else {
                    return nil
                }
            }
        }
        return outline
    }
    
    func modelString( _ object: AnyObject ) -> String? {

        let newString = object as? String
        if newString != nil {
            return newString
        } else {
            let hopefulString = String(describing: object)
            print( "Got unrecognized type: \(hopefulString)" )
            return nil // hopefulString?
        }
    }
}
