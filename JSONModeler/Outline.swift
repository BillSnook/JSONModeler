//
//  Outline.swift
//  JSONModeler
//
//  Created by William Snook on 6/11/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation


enum EntryType {
    case dictionary
    case array
    case string
    case unknown
}

class Outline: NSObject {
    let key:        String
    let value:      String
    let childType:  EntryType
    var children:   [Outline]
    
    init( key: String, value: String, type: EntryType ) {
        self.key = key
        self.value = value
        self.childType = type
        self.children = [Outline]()
    }
    
    func addChildren( _ children: [Outline] ) {
        
        for child in children {
            self.children.append( child )
        }
    }

}
