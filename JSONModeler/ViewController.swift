//
//  ViewController.swift
//  JSONModeler
//
//  Created by William Snook on 6/6/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var outlineTableView: NSOutlineView!
    @IBOutlet weak var displayTextView: NSTextView!
    
    @IBOutlet weak var saveInfoButton: NSButton!
    
    @IBOutlet weak var fileLoadIndicator: NSProgressIndicator!
    
    @IBOutlet weak var topButton: NSButton!
    @IBOutlet weak var bottomRightButton: NSButton!
    
    @IBOutlet weak var modelNameTextField: NSTextField!
    @IBOutlet weak var moduleNameTextField: NSTextField!
    
    @IBOutlet weak var modelNameLabel: NSTextField!
    @IBOutlet weak var moduleNameLabel: NSTextField!
    
    
    var tokens: [String]?
    
    var jsonObject: AnyObject?
    
    var outlines: Outline?
    
    var fileName: String?

    
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
                
                displayTokens( tokens! )
                
                let parser = Parser( tokens! )
                jsonObject = parser.processTokens()
                guard jsonObject != nil else { return }
                
//                print( "Parser returns JSONObject: \(jsonObject!)" )
                if var pathName = self.selectedItem?.lastPathComponent {    // Get clean name of json source file
                    if (pathName.hasSuffix( ".json" )) {
                        let endIndex = pathName.endIndex
                        pathName.removeSubrange(Range(uncheckedBounds: (lower: pathName.index(endIndex, offsetBy: -5), upper: endIndex)))
                        self.fileName = pathName
                        print( "\(self.fileName!)" )
                    }
                }
                if fileName == nil {
                    fileName = "Root"
                }
                
                let builder = Builder( jsonObject!, fileName: fileName! )
                outlines = builder.buildModelFile()
                
                outlineTableView.reloadData()
                
                saveInfoButton.isEnabled = ( outlines != nil )
            }
            fileLoadIndicator.stopAnimation( nil )
        }
    }
    

    // View events
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        topButton.title = "TBD"
        topButton.isHidden = true
        bottomRightButton.title = "Display Model FIle"
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
            }
        }
    }
    
    @IBAction func saveInfo(_ sender: NSButton) {
        
        let filer = Filer( model: modelNameTextField.stringValue, module: moduleNameTextField.stringValue, outline: outlines! )
        
        let response = filer.buildModelFile()
        print( "response: \(response)" )
        
        displayRender( filer.fileContents )
        
        saveInfoButton.isEnabled = false
    }
    
    @IBAction func doubleClickEntry(_ sender: NSOutlineView) {
        
        let item = sender.item(atRow: sender.clickedRow)
        
        if sender.isItemExpanded(item) {
            sender.collapseItem(item)
        } else {
            sender.expandItem(item)
        }
    }

    @IBAction func changedName(_ sender: NSTextField) {
        print( "Changed string: \(sender.stringValue)" )
        let selectedItem = outlineTableView.selectedRow
        if selectedItem != -1 {
            var item = outlineTableView.item(atRow: selectedItem ) as! Outline
            print( "Changed item \(item.key) from \(item.value) to \(sender.stringValue)" )
            item.name = sender.stringValue
        }
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

    func displayRender( _ string: String) {

        let paragraphStyle = NSMutableParagraphStyle.default().mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 20
        paragraphStyle?.alignment = .left
//        paragraphStyle?.tabStops = [ NSTextTab(type: .leftTabStopType, location: 240) ]
        
        let textAttributes: [String: Any] = [
            NSFontAttributeName: NSFont.userFixedPitchFont(ofSize: 14)!,
            NSParagraphStyleAttributeName: paragraphStyle ?? NSParagraphStyle.default()
        ]
        
        displayTextView.textStorage?.setAttributedString( NSAttributedString(string: string, attributes: textAttributes) )
    }
    
    func displayTokens( _ tokens: [String]) {
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


// MARK: - Outline view data source delegate

extension ViewController: NSOutlineViewDataSource {
    
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        if let outlineItem = item as? Outline {
            return outlineItem.children.count
        }
        if let outlineCount = outlines?.children.count {
            return outlineCount
        }
        return 0
    }
 
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        if let outlineItem = item as? Outline {
            return outlineItem.children[index]
        }
        if let outlineItem = outlines {
            return outlineItem.children[index]
        }
        return outlines as Any
    }

    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        if let outlineItem = item as? Outline {
            switch outlineItem.childType {
            case .dictionary, .array:
                return true
            default:
                return false
            }
        }
        return false
    }

//    func outlineView(_ outlineView: NSOutlineView, objectValueFor tableColumn: NSTableColumn?, byItem item: Any?) -> Any? {
//        
//        print( "tableColumn title: \(String(describing: tableColumn?.title))")
//        var value = ""
//        if item is DictionaryType {
//            value = "Dictionary"
//        } else if item is ArrayType {
//            value = "Array"
//        } else if let stringItem = item as? String {
//            value = stringItem
//        } else if let outlineItem = item as? Outline {
//            value = outlineItem.key
//        } else {
//            value = "NoneSuch"
//        }
//        return value
//    }

}


// MARK: - Outline view delegate

extension ViewController: NSOutlineViewDelegate {
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var view: NSTableCellView?

        if let outlineItem = item as? Outline {
            let tableID = tableColumn?.identifier
            var displayValue = ""
            if tableID == "KeyCell" {
                displayValue = outlineItem.key
            } else {
                if tableID == "ValueCell" {
                    if ( outlineItem.name != "" ) {
                        displayValue = outlineItem.name
                    } else {
                        displayValue = outlineItem.value
                    }
                } else {
                    displayValue = outlineItem.optional ? "Yes" : "No"
                }
            }
            view = outlineView.make(withIdentifier: tableID!, owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.stringValue = displayValue
                textField.sizeToFit()
            }
        }
        
        return view
    }

//    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {
//        
//        let tableID = tableColumn?.identifier
//        if tableID == "ValueCell" {
//            return true
//        } else {
//            return false
//        }
//    }
//    
//    func outlineViewSelectionDidChange(_ notification: Notification) {
//
//        guard let outlineView = notification.object as? NSOutlineView else {
//            return
//        }
//
//        let selectedIndex = outlineView.selectedRow
//        // Do something
//    }
//
//    func outlineView(_ outlineView: NSOutlineView, shouldSelect tableColumn: NSTableColumn?) -> Bool {
//        
//        let tableID = tableColumn?.identifier
//        if tableID == "ValueCell" {
//            return true
//        } else {
//            return false
//        }
//    }
//    
//    
//    
//    func outlineView(_ outlineView: NSOutlineView, didClick tableColumn: NSTableColumn) {
//        
//        let tableID = tableColumn.identifier
//        print( "Click in column \(tableID)" )
//    }
    
}

