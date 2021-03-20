//
//  ContentView.swift
//  TextKitEditor
//
//  Created by Mattia Righetti on 20/03/21.
//

import SwiftUI

struct EditorView: UIViewRepresentable {
    let code: String
    
    func makeUIView(context: Context) -> UITextView {
        let codeString = CodeString()
        let textStorage = TextStorage()
        textStorage.content = codeString
        textStorage.font = UIFont(name: "Menlo", size: 13)!
        
        let layoutManager = LayoutManager()
        textStorage.addLayoutManager(layoutManager)
        layoutManager.lineHeight = 1
        layoutManager.showParagraphNumbers = true
        layoutManager.tabWidth = 4
        
        let textContainer = TextContainer()
        layoutManager.addTextContainer(textContainer)
        
        let view = UITextView(frame: CGRect(origin: .zero, size: .zero), textContainer: textContainer)
        view.translatesAutoresizingMaskIntoConstraints = false
        view.keyboardDismissMode = .interactive
        view.spellCheckingType = .no
        view.text = code
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {}
}

struct TKEView_Previews: PreviewProvider {
    static var previews: some View {
        let codeString = """
        //
        //  ContentView.swift
        //  TextKitEditor
        //
        //  Created by Mattia Righetti on 20/03/21.
        //

        import SwiftUI

        struct TKEView: UIViewRepresentable {
            let code: String
            
            func makeUIView(context: Context) -> UITextView {
                let codeString = TKECodeString()
                let textStorage = TKETextStorage()
                textStorage.content = codeString
                textStorage.font = UIFont(name: "Menlo", size: 13)
                
                let layoutManager = TKELayoutManager()
                layoutManager.lineHeight = 1
                layoutManager.showParagraphNumbers = true
                layoutManager.tabWidth = 4
                textStorage.addLayoutManager(layoutManager)
                
                let textContainer = TKETextContainer()
                layoutManager.addTextContainer(textContainer)
                
                let view = UITextView(frame: CGRect(origin: .zero, size: .zero), textContainer: textContainer)
                view.translatesAutoresizingMaskIntoConstraints = false
                view.keyboardDismissMode = .interactive
                view.spellCheckingType = .no
                return view
            }
            
            func updateUIView(_ uiView: UITextView, context: Context) {}
        }
        """
        EditorView(code: codeString)
    }
}
