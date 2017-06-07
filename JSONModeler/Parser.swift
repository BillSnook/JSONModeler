//
//  Parser.swift
//  JSONModeler
//
//  Created by William Snook on 6/7/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation


class Parser {
    
    class func processTokens(_ tokens: [String]) -> AnyObject? {
        
        var returnJSONObject: AnyObject?
        
        var dictInset = 0
//        var arryInset = 0
        var commaCount = 0
        var colonCount = 0
        var otherCount = 0
        
        var startSymbolExpected = true
        var dictKeyExpected = false
        var dictValueExpected = false
        var colonExpected = false
//        var commaExpected = false
        var dictEntryComplete = false
        
        var jsonStack = Stack<Dictionary<String, Any>>()
        var currentDictionary: [String:Any]?
        var currentKey = ""
//        var currentToken = ""
        
        for token in tokens {
            switch token {
            case "{":
                print( "Got dictionary start symbol     -> {" )
                if !startSymbolExpected {
                    print( "Error, start symbol not expected" )
                    return nil
                }
                startSymbolExpected = false
                dictInset += 1
                dictKeyExpected = true
                currentDictionary = [String: Any]()
                if currentDictionary == nil {
                    print( "Error, unable to create dictionary" )
                    return nil
                }
//                jsonStack.push( currentDictionary! )
            case "}":
                print( "Got dictionary end symbol       -> }" )
                dictInset -= 1
                if dictInset < 0 {
                    print( "Error, dictionary bracket mismatch" )
                    return nil
                }
                if !dictEntryComplete {
                    print( "Error, dictionary end bracket found when not expected" )
                    return nil
                }
//                dictEntryComplete = false
                startSymbolExpected = true
                // currentDictionary done, pop current dictionary
//                let _ = jsonStack.pop()
                if returnJSONObject == nil {
                    returnJSONObject = currentDictionary! as AnyObject
                } else {
                }
                
//            case "[":
//                arryInset += 1
//            case "]":
//                arryInset -= 1
            case ",":
                print( "Got dictionary seperator symbol -> ," )
                commaCount += 1
                if !startSymbolExpected {
                    print( "Error, start symbol not expected" )
                    return nil
                }
                startSymbolExpected = false
                if dictEntryComplete {
                    dictKeyExpected = true
                }
                dictEntryComplete = false
            case ":":
                print( "Got dictionary indicator symbol -> :" )
                colonCount += 1
                if colonExpected {
                    colonExpected = false
                    dictValueExpected = true
                }
            default:
                print( "Got dictionary entry symbol     -> \(token)" )
                otherCount += 1
                if dictKeyExpected {
                    dictKeyExpected = false
                    currentKey = token
                    colonExpected = true
                } else if dictValueExpected {
                    dictValueExpected = false
                    currentDictionary![currentKey] = token
                    dictEntryComplete = true
                    startSymbolExpected = true
                }
            }
        }
        if !startSymbolExpected {
            print( "Error, at end but not expecting a start symbol" )
            return nil
        }
        if jsonStack.peek() != nil {
            print( "Error, at end but jsonStack is not empty" )
            return nil
        }
        print( "returnJSONObject is \(returnJSONObject!)" )
        return returnJSONObject
    }
    
}


struct Stack<Element> {
    fileprivate var array: [Element] = []
    
    mutating func push(_ element: Element) {
        array.append(element)
    }
    
    mutating func pop() -> Element? {
        return array.popLast()
    }
    
    func peek() -> Element? {
        return array.last
    }
    
    var isEmpty: Bool {
        return array.isEmpty
    }
    
    var count: Int {
        return array.count
    }
}

extension Stack: CustomStringConvertible {
    
    var description: String {
        
        let topDivider = "---Stack---\n"
        let bottomDivider = "\n-----------\n"
        
        let stackElements = array.map { "\($0)" }.reversed().joined(separator: "\n")
        
        return topDivider + stackElements + bottomDivider
    }
}
