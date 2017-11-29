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
    @IBOutlet weak var saveSelectedButton: NSButton!
    
    @IBOutlet weak var fileLoadIndicator: NSProgressIndicator!

    @IBOutlet weak var modelNameTextField: NSTextField!
    @IBOutlet weak var moduleNameTextField: NSTextField!
    
    @IBOutlet weak var modelNameLabel: NSTextField!
    @IBOutlet weak var moduleNameLabel: NSTextField!
    
    @IBOutlet weak var emptyArraysColorWell: NSColorWell!
    @IBOutlet weak var leafNodesColorWell: NSColorWell!
    
    var jsonObject: AnyObject?
    
    var outlines: Outline?

    var modeler: Modeler?
    var filer: Filer?

    var fileName = ""
    var modelName = ""
    var moduleName = ""

    var selectedItem: URL? {    // Set when file is opened
        didSet {
            displayTextView.string = ""
            saveInfoButton.isEnabled = false
            
            guard let selectedUrl = selectedItem else { return }    // Got file URL
            
            fileLoadIndicator.startAnimation( nil )
            let infoString = try? String(contentsOf: selectedUrl)   // Read it into a string
            guard let textString = infoString, !textString.isEmpty else { return }
            
            var tokens: [String]?

            let tokenizer = Tokenizer()
            tokens = tokenizer.makeTokens( JSON: textString )       // Break it into meaningful tokens
            guard tokens != nil else { return }
            
//            displayTokens( tokens! )
            
            let parser = Parser( tokens! )
            jsonObject = parser.processTokens()                     // Produce a swift dictionary or array
            guard jsonObject != nil else { return }
            
            if var pathName = selectedItem?.lastPathComponent {     // Get clean name of json source file
                if (pathName.hasSuffix( ".json" )) {
                    let endIndex = pathName.endIndex
                    pathName.removeSubrange(Range(uncheckedBounds: (lower: pathName.index(endIndex, offsetBy: -5), upper: endIndex)))
                    fileName = pathName                             // For default model name
                }
            }
            if fileName.isEmpty {
                fileName = "Root"
            }
            
            let builder = Builder( jsonObject!, fileName: fileName )
            outlines = builder.buildModelFile()                     // Build outline view model from object
            
            if outlines != nil {
                outlineTableView.reloadData()                       // Profit - er, show table of model
                makeModel( outlines )                               // Display top level model file
            }
            
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
    
    
    // MARK: - View events
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        saveInfoButton.title = "Save All"
        saveInfoButton.isEnabled = false

        // Live updating of color wells
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.emptyColorChanged), name: NSNotification.Name.NSColorPanelColorDidChange, object: emptyArraysColorWell)
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.leafColorChanged), name: NSNotification.Name.NSColorPanelColorDidChange, object: leafNodesColorWell)
    }

    @objc func emptyColorChanged(sender: NSColorWell?) {
        print("emptyColorChanged")
    }
    
    @objc func leafColorChanged(sender: NSColorWell?) {
        print("leafColorChanged")
    }
    
    
//    override var representedObject: Any? {
//        didSet {
//        // Update the view, if already loaded.
//        }
//    }

    // Action events
    @IBAction func saveSelected(_ sender: NSButton) {
        
        
    }
    
    @IBAction func saveInfo(_ sender: NSButton) {
        
        guard outlines != nil else { return }
        
        saveInfoButton.isEnabled = false

        makeModel( nil )
        
        filer = Filer( creatorName: modelName, moduleName: moduleName )
        guard filer != nil else { return }
        
        filer!.saveFile( outlines! )
        
        saveInfoButton.isEnabled = true
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

    
// MARK: - Display routines

extension ViewController {
    
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
    
    func makeModel( _ outline: Outline?) {
        
        moduleName = self.fileName
        let moduleText = moduleNameTextField.stringValue
        if !moduleText.isEmpty {
            moduleName = moduleText
        }
        
        guard outlines != nil || outline != nil else { return }
        let rootOutline = outline == nil ? outlines! : outline!

        modelName = rootOutline.key
        let modelText = modelNameTextField.stringValue
        if !modelText.isEmpty {
            modelName = modelText
        }
//        modelName = modelName!.capitalized // Not quite, also removes existing camelcase formatting
        
        modeler = Modeler( creator: modelName, module: moduleName, outline: rootOutline )
        guard modeler != nil else { return }
        
        modeler!.buildModelFile()
        guard !modeler!.fileContents.isEmpty else { return }
        
        displayRender( modeler!.fileContents )    // Show it
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
                    textField.textColor = leafNodesColorWell.color // NSColor.init(red: 0.3, green: 0.7, blue: 0.4, alpha: 1.0)
                } else {
                    if outlineItem.emptyArray {
                        textField.textColor = emptyArraysColorWell.color //NSColor.init(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0)
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
