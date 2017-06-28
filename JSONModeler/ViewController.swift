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
    
    @IBOutlet weak var bottomRightButton: NSButton!
    
    @IBOutlet weak var modelNameTextField: NSTextField!
    @IBOutlet weak var moduleNameTextField: NSTextField!
    
    @IBOutlet weak var modelNameLabel: NSTextField!
    @IBOutlet weak var moduleNameLabel: NSTextField!
    
    
    
    var jsonObject: AnyObject?
    
    var outlines: Outline?
    
    var fileName: String?

    
    var selectedItem: URL? {
        didSet {
            displayTextView.string = ""
            saveInfoButton.isEnabled = false
            
            guard let selectedUrl = selectedItem else { return }    // Got file URL
            
            fileLoadIndicator.startAnimation( nil )
            let infoString = try? String(contentsOf: selectedUrl)   // Read it into a string
            guard let textString = infoString, !textString.isEmpty else { return }
            
            var tokens: [String]?
            tokens = produceTokensFrom( JSON: textString )          // Break it into meaningful tokens
            guard tokens != nil else { return }
            
            displayTokens( tokens! )
            
            let parser = Parser( tokens! )
            jsonObject = parser.processTokens()                     // Produce a swift dictionary or array
            guard jsonObject != nil else { return }
            
            if var pathName = self.selectedItem?.lastPathComponent {    // Get clean name of json source file
                if (pathName.hasSuffix( ".json" )) {
                    let endIndex = pathName.endIndex
                    pathName.removeSubrange(Range(uncheckedBounds: (lower: pathName.index(endIndex, offsetBy: -5), upper: endIndex)))
                    self.fileName = pathName                            // For default model name
                }
            }
            if fileName == nil {
                fileName = "Root"
            }
            
            let builder = Builder( jsonObject!, fileName: fileName! )
            outlines = builder.buildModelFile()                     // Build outline view model from object
            
            outlineTableView.reloadData()                           // Profit
            
            saveInfoButton.isEnabled = ( outlines != nil )
            
            fileLoadIndicator.stopAnimation( nil )
        }
    }
    
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
    
    
    // View events
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        bottomRightButton.title = "Display Model FIle"
    }

//    override var representedObject: Any? {
//        didSet {
//        // Update the view, if already loaded.
//        }
//    }

    // Action events
    @IBAction func saveInfo(_ sender: NSButton) {
        
        var modelName = self.fileName
        let modelText = modelNameTextField.stringValue
        if !modelText.isEmpty {
            modelName = modelText
        }
//        modelName = modelName!.capitalized // Not quite, also removes existing camelcase formatting

        var moduleName = "ModuleName"
        let moduleText = moduleNameTextField.stringValue
        if !moduleText.isEmpty {
            moduleName = moduleText
        }

        let filer = Filer( model: modelName!, module: moduleName, outline: outlines! )
        
        let _ = filer.buildModelFile()
        
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

        let selectedRow = outlineTableView.selectedRow
        if selectedRow != -1 {
            let item = outlineTableView.item(atRow: selectedRow ) as! Outline
            let selectedColumn = outlineTableView.selectedColumn
            if selectedColumn == 1 {    // Value
                item.value = sender.stringValue
            } else {                    // Optional
                item.optional = sender.stringValue == "Yes" ? true : false
            }
        }
    }
    
    @IBAction func expandAll(_ sender: NSButton) {
        
        outlineTableView.expandItem( nil, expandChildren: true )
    }
    
    @IBAction func collapseAll(_ sender: NSButton) {
        
        outlineTableView.collapseItem( nil, collapseChildren: true )
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
        }
        let paragraphStyle = NSMutableParagraphStyle.default().mutableCopy() as? NSMutableParagraphStyle
        paragraphStyle?.minimumLineHeight = 24
        paragraphStyle?.alignment = .left
        
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
            var editable = false
//            var selectable = false
            
            if tableID == "KeyCell" {
                displayValue = outlineItem.key
            } else {
                if tableID == "ValueCell" {
                    displayValue = outlineItem.value
                    if outlineItem.childType != .string {
                        editable = true
                    }
                } else {
                    displayValue = outlineItem.childType.rawValue
//                    displayValue = outlineItem.optional ? "Yes" : "No"
//                    selectable = true
                }
            }
            
            view = outlineView.make(withIdentifier: tableID!, owner: self) as? NSTableCellView
            if let textField = view?.textField {
                textField.isEditable = editable
//                textField.isSelectable = selectable
                textField.stringValue = displayValue
                if outlineItem.leaf {
                    textField.textColor = NSColor.init(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
                } else {
                    if outlineItem.emptyArray {
                        textField.textColor = NSColor.gray
                    } else {
                        textField.textColor = NSColor.black
                    }
                }
                textField.sizeToFit()
            }
        }
        
        return view
    }

//    func outlineView(_ outlineView: NSOutlineView, shouldEdit tableColumn: NSTableColumn?, item: Any) -> Bool {

//        let tableID = tableColumn?.identifier
//        if tableID == "ValueCell" {
//            let outline = item as? Outline
//            if outline != nil {
//                if (outline?.children.count)! > 0 {
//                    return true
//                }
//            }
//        } else if tableID == "OptionalCell" {
//            return true
//        }
//        return false
//    }

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
//    }
}
