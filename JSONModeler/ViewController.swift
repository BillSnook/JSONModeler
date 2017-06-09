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
                tokens = produceTokensFrom( JSON: textString )
                guard tokens != nil else { return }
                displayRender( tokens! )
                
                let parser = Parser( tokens! )
                jsonObject = parser.processTokens()
                if jsonObject != nil {
                    print( "Parser returns JSONObject: \(jsonObject!)" )
                } else {
                    print( "Parser returns nil" )
                }
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
                    if !quoters.contains( character ) {
                        quoteString += "\\"
                    }
                    quoteString += String( character )
                    isEscapingNextCharacter = false
                    continue
                }
                if character == "\\" {  // The presence of this character escapes the value of the next one
//                    quoteString += String( character ) // Comment out to remove escaping characters
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
//                quoteString += String( character )    // Comment out to retain quotes around keys and values
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
