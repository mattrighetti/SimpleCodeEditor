//
//  TextKitEditorApp.swift
//  TextKitEditor
//
//  Created by Mattia Righetti on 20/03/21.
//

import SwiftUI

@main
struct TextKitEditorApp: App {
    var codeString: String {
        if let filepath = Bundle.main.path(forResource: "sample", ofType: "txt") {
            do {
                return try String(contentsOfFile: filepath)
            } catch {
                return "cannot load file"
            }
        } else {
            // example.txt not found!
            return "cannot locate file"
        }
    }
    
    var body: some Scene {
        WindowGroup {
            EditorView(code: codeString as String)
        }
    }
}
