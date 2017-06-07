//
//  ViewController.swift
//  JSONModeler
//
//  Created by William Snook on 6/6/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {

    @IBOutlet var displayTextView: NSTextView!
    @IBOutlet weak var saveInfoButton: NSButton!
    
    @IBOutlet weak var fileLoadIndicator: NSProgressIndicator!
    
    var tokens: [String]?

    
    var selectedItem: URL? {
        didSet {
            displayTextView.string = ""
            saveInfoButton.isEnabled = false
            
            guard let selectedUrl = selectedItem else { return }
            
            fileLoadIndicator.startAnimation( nil )
            let infoString = try? String(contentsOf: selectedUrl)
            guard let textString = infoString else { return }
            if !textString.isEmpty {
                tokens = produceTokensFrom( JSON: textString )
                guard tokens != nil else { return }
                displayRender( tokens! )
                processTokens( tokens! )
                saveInfoButton.isEnabled = true
            }
            fileLoadIndicator.stopAnimation( nil )
        }
    }
    

    // View events
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    // Action events
    @IBAction func findJSONFile(_ sender: NSButton) {
        guard let window = view.window else { return }
        
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        panel.allowedFileTypes = ["json"]
        
        panel.beginSheetModal(for: window) { (result) in
            if result == NSFileHandlingPanelOKButton {
                self.selectedItem = panel.urls[0]
//                print(self.selectedItem)
            }
        }
    }
    
    @IBAction func saveInfo(_ sender: NSButton) {
        
        saveInfoButton.isEnabled = false
    }
    
}

    
    // MARK: - Getting file or folder information

extension ViewController {
    
    func produceTokensFrom(JSON text: String) -> [String] {
        
//        print( text )
        
        var tokens = [String]()
        let brackets: Set<Character> = ["{","}","[","]",":",","]
        let quoters: Set<Character> = ["\"","\'"]
        let ignored: Set<Character> = [" ","\t","\n","\r"]
        var index = 0
        
        var parseString = ""
        var quoteString = ""
        
        var inQuotedString = false
        var isEscapingNextCharacter = false
        
        for character in text.characters {
            
            if inQuotedString {
                if isEscapingNextCharacter {
                    quoteString += String( character )
                    isEscapingNextCharacter = false
                    continue
                }
                if character == "\\" {  // The presence of this character escapes the value of the next one
                    quoteString += String( character )
                    isEscapingNextCharacter = true
                    continue
                }
            } else {
                if ignored.contains( character ) {
                    continue
                }
            }
            if quoters.contains( character ) { // May match ' with ", use: character == "\""
                inQuotedString = !inQuotedString
                quoteString += String( character )
                if !inQuotedString {
                    tokens.append( quoteString )
                    index += 1
                    quoteString = ""
                }
                continue
            } else {
                if inQuotedString {
                    quoteString += String( character )
                    continue
                }
            }
            
            if brackets.contains( character ) {
                if !parseString.isEmpty {
                    tokens.append( parseString )
                    index += 1
                    parseString = ""
                }
                tokens.append( String( character ) )
                index += 1
            } else {
                parseString += String( character )
            }
        }
        if !parseString.isEmpty {   // Should be an error, should end on a bracket
            tokens.append( parseString )
            print( "Error at end, leftover data: \(parseString)" )
        }
        if inQuotedString {
            print( "Error at end, still in quoted string" )
        }
        
        return tokens
    }

    func processTokens(_ tokens: [String]) {

        var dictInset = 0
//        var arryInset = 0
        var commaCount = 0
        var colonCount = 0
        var otherCount = 0
        
        var dictKeyExpected = false
        var dictValueExpected = false
        var colonExpected = false
        var dictEndExpected = false
        
//        var jsonDictionary = Stack<Dictionary<String, Any>>()
//        var currentDictionary: [String:Any]?
        var currentKey = ""
        var currentToken = ""
        
        for token in tokens {
            switch token {
            case "{":
                dictInset += 1
                dictKeyExpected = true
//                currentDictionary = [String: Any]()
//                if currentDictionary != nil {
//                    jsonDictionary.push( currentDictionary! )
//                }
            case "}":
                dictInset -= 1
                if dictInset < 0 {
                    print( "Error, dictionary bracket mismatch" )
                }
                if !dictEndExpected {
                    print( "Eror, dictionary end bracket found when not expected" )
                }
                // currentDictionary done, pop current dictionary
//            case "[":
//                arryInset += 1
//            case "]":
//                arryInset -= 1
            case ",":
                commaCount += 1
            case ":":
                colonCount += 1
                if colonExpected {
                    colonExpected = false
                    dictValueExpected = true
                }
            default:
                otherCount += 1
                if dictKeyExpected {
                    dictKeyExpected = false
                    currentKey = token
                    colonExpected = true
                } else if dictValueExpected {
                    dictValueExpected = false
//                    currentDictionary[currentKey] = token
                    dictEndExpected = true
                }
            }
        }
        
    }
    
    func displayRender( _ tokens: [String]) {
        var parsedText = ""
        for token in tokens {
            parsedText += token + "\n"
//            print( token )
        }
        let paragraphStyle = NSMutableParagraphStyle.default().mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 24
        paragraphStyle?.alignment = .left
        paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]
        
        let textAttributes: [String: Any] = [
            NSFontAttributeName: NSFont.systemFont(ofSize: 14),
            NSParagraphStyleAttributeName: paragraphStyle ?? NSParagraphStyle.default()
        ]
        
        displayTextView.textStorage?.setAttributedString( NSAttributedString(string: parsedText, attributes: textAttributes) )
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
