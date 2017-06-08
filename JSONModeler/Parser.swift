//
//  Parser.swift
//  JSONModeler
//
//  Created by William Snook on 6/7/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation


typealias DirType = [String:Any]

enum ParseState {
    case waitForStart
    
    case waitForKey
    case waitForColon
    case waitForValue
    case doneWithDictEntry
    
    case allMessedUp
    
    case end
}

class Parser {
   
    var dictInset = 0
    var commaCount = 0
    var colonCount = 0
    var otherCount = 0

    var tokens: [String]
    var count: Int
    
    
    init(_ tokenList: [String]) {
        tokens = tokenList
        count = tokens.count
    }
    
    
    func processTokens(_ index: inout Int) -> AnyObject? {
        
        var currentKey = ""

        var currentDictionary: DirType?
        
        var state = ParseState.waitForStart
        
        
        while index < count {   // Check token, check state, do operation, next state
            let token = tokens[index]
            index += 1
            if state == .allMessedUp {
                break
            }
            switch token {
                
            case "{":
                dictInset += 1
                switch state {
                    
                case .waitForStart:
                    print( "Got dictionary start symbol     -> {" )
                    state = .waitForKey
                    currentDictionary = DirType()
                    if currentDictionary == nil {
                        print( "Error, unable to create dictionary" )
                        return nil
                    }
                    
                case .waitForValue:

                    //                    }
                    index -= 1
                    currentDictionary![currentKey] = processTokens( &index )
                    state = .waitForStart
                default:
                    print( "Error, start symbol not expected, state: \(state)" )
                    state = .allMessedUp
                }
                
            case "}":
                print( "Got dictionary end symbol       -> }" )
                dictInset -= 1
                if dictInset < 0 {
                    print( "Error, dictionary bracket mismatch" )
                    return nil
                }
                switch state {
                    
                case .waitForStart:
                    state = .waitForStart
                default:
                    print( "Error, dictionary end symbol found when not expected, state: \(state)" )
                    state = .allMessedUp
                }
                
//            case "[":
//                arryInset += 1
//            case "]":
//                arryInset -= 1
                
            case ",":
                print( "Got dictionary separator symbol -> ," )
                commaCount += 1
                switch state {
                    
                case .waitForStart:
                    state = .waitForKey
                    
                default:
                    print( "Error, ',' symbol not expected, state: \(state)" )
                    state = .allMessedUp
                }

            case ":":
                print( "Got dictionary indicator symbol -> :" )
                colonCount += 1
                switch state {
                    
                case .waitForColon:
                    state = .waitForValue
                    
                default:
                    print( "Error, ':' symbol not expected, state: \(state)" )
                    state = .allMessedUp
                }
                
            default:
                print( "Got dictionary entry symbol     -> \(token)" )
                otherCount += 1
                switch state {
                    
                case .waitForKey:
                    state = .waitForColon
                    currentKey = token
                    
                case .waitForValue:
                    state = .waitForStart
                    currentDictionary![currentKey] = token
                    
                default:
                    state = .allMessedUp
                    print( "Error, dictionary entry symbol was unexpected, state: \(state)" )
                }
            }
        }

        switch state {
        case .allMessedUp:
            print( "Error, exit parser due to state error" )
        case .waitForStart:
            let returnJSONObject = currentDictionary! as AnyObject
            return returnJSONObject
        default:
            print( "Error, at end but not in the waitForStart state" )
        }
        return nil
    }
    
}
