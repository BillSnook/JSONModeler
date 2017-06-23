//
//  Outline.swift
//  JSONModeler
//
//  Created by William Snook on 6/11/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation


enum EntryType: String {
    case dictionary = "Dictionary"
    case array = "Array"
    case string = "String"
    case unknown = "NSObject"
}

class Outline: NSObject {
    let key:        String
    var value:      String
    var itemType:   EntryType
    let childType:  EntryType
    var optional:   Bool
    var leaf:       Bool
    var children:   [Outline]
    
    init( key: String, value: String, type: EntryType ) {
        self.key = key
        self.value = value
        self.itemType = .unknown
        self.childType = type
        self.optional = false
        self.leaf = false
        self.children = [Outline]()
    }
    
    func addChildren( _ children: [Outline] ) {
        
        for child in children {
            self.children.append( child )
        }
    }

}
