//
//  Filer.swift
//  JSONModeler
//
//  Created by William Snook on 6/11/17.
//  Copyright © 2017 mobileforming. All rights reserved.
//

import Foundation
import Cocoa


class Filer {
    
    var creatorName: String
    var moduleName: String
    var url: URL?
    
    init( creatorName: String, moduleName: String ) {
        self.creatorName = creatorName
        self.moduleName = moduleName
    }
    // File actions
    func saveFile( _ outline: Outline ) {
        
        let panel = NSSavePanel()
        panel.title = "Save Models"
        panel.prompt = "Save All"
        panel.nameFieldLabel = "Directory Name"
        panel.message = "Directory name for model files"
        
        panel.nameFieldStringValue = creatorName
        
        guard let window = NSApplication.shared().mainWindow else { return }
        panel.beginSheetModal(for: window) { (result) in
            if result == NSFileHandlingPanelOKButton {
                self.url = panel.url
                guard self.url != nil else { return }
                self.writeFiles( outline, toDir: panel.nameFieldStringValue )
            }
        }
    }
    
    func writeFiles( _ outline: Outline, toDir: String ) {
        
        guard url != nil else { return }
        let dirURL = URL(fileURLWithPath: toDir, isDirectory: true, relativeTo: url)
        do {
            try FileManager.default.createDirectory(at: dirURL, withIntermediateDirectories: false, attributes: nil)
            writeOutline( outline, inDir: dirURL )
        } catch {
            print("error creating directory at url: \(dirURL.absoluteString), error: \(error)")
        }
    }
    
    func writeOutline( _ outline: Outline, inDir: URL  ) {
        
        for child in outline.children {
            writeOutline( child, inDir: inDir )
        }
        writeModel( outline, inDir: inDir )
    }
    
    func writeModel( _ outline: Outline, inDir: URL  ) {
        
        guard outline.childType != .string else  { return }
        
        let name = outline.key
        let fullURL = URL(fileURLWithPath: name + ".swift", relativeTo: inDir)

        let modeler = Modeler( creator: creatorName, module: moduleName, outline: outline )
        modeler.buildModelFile()
        guard !modeler.fileContents.isEmpty else { return }
        
        do {        // Write to disk
            try modeler.fileContents.write(to: fullURL, atomically: false, encoding: .utf8)
        } catch {
            print("error writing to url: \(String(describing: url)), error: \(error)")
        }
    }
    
}
