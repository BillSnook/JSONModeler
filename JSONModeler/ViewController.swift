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
    
    var jsonObject: AnyObject?
    
    
    var selectedItem: URL? {
        didSet {
            displayTextView.string = ""
            saveInfoButton.isEnabled = false
            
            guard let selectedUrl = selectedItem else { return }
            
            fileLoadIndicator.startAnimation( nil )
            let infoString = try? String(contentsOf: selectedUrl)
            guard let textString = infoString else { return }
            if !textString.isEmpty {
                let processedFile = processFileContents( textString )
                let formattedText = displayFileContents( processedFile )
                displayTextView.textStorage?.setAttributedString( formattedText )
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
    
    func processFileContents(_ text: String) -> String {
        
//        print( text )
        
        var tokens = [String]()
        var quoted = ""
        let brackets: Set<Character> = ["{","}","[","]",":",","]
        let ignored: Set<Character> = [" ", "\n"]
        var index = 0
        
        var parseString = ""
        
        var inQuotedString = false
        
        for character in text.characters {
            if ignored.contains( character ) {
                continue
            }
            if character == "\"" {
                inQuotedString = !inQuotedString
                quoted += String( character )
                if !inQuotedString {
                    tokens.append( quoted )
                    index += 1
                    quoted = ""
                }
                continue
            } else {
                if inQuotedString {
                    quoted += String( character )
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
        
        var responseText = ""
        for token in tokens {
            responseText += token + "\n"
//            print( token )
        }
        
        jsonObject = processTokenList( tokens )
        
        return responseText
    }

    func processTokenList(_ tokens: [String]) -> AnyObject? {
   
        var tempObject: AnyObject?
        
        var dictInset = 0
        var arryInset = 0
        var commaCount = 0
        var colonCount = 0
        var otherCount = 0
        
        var dictKeyExpected = false
        var dictValueExpected = false
        var colonExpected = false
        var dictEndExpected = false
//        var arrayEntryExpected = false
        
        var topDictionary = [String: Any]()
        var currentDictionary = topDictionary
        var currentKey = ""
        var currentToken = ""
        
        for token in tokens {
            switch token {
            case "{":
                dictInset += 1
                dictKeyExpected = true
            case "}":
                dictInset -= 1
            case "[":
                arryInset += 1
            case "]":
                arryInset -= 1
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
                    currentDictionary[currentKey] = token
                    dictEndExpected = true
                }
            }
        }
        
        return tempObject
    }
    
    func displayFileContents(_ text: String) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle.default().mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 24
        paragraphStyle?.alignment = .left
        paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]
        
        let textAttributes: [String: Any] = [
            NSFontAttributeName: NSFont.systemFont(ofSize: 14),
            NSParagraphStyleAttributeName: paragraphStyle ?? NSParagraphStyle.default()
        ]
        
        let formattedText = NSAttributedString(string: text, attributes: textAttributes)
        return formattedText
    }
    
    
}
