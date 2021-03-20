//
//  TKECodeString.swift
//  TextKitEditor
//
//  Created by Mattia Righetti on 20/03/21.
//

import Foundation
import UIKit

class CodeString: NSString {
    var imp: NSMutableString
    
    override init() {
        imp = NSMutableString()
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - String Accessors
    
    override var length: Int {
        imp.length
    }
    
    override func character(at index: Int) -> unichar {
        imp.character(at: index)
    }
    
    override func getCharacters(_ buffer: UnsafeMutablePointer<unichar>, range: NSRange) {
        imp.getCharacters(buffer, range: range)
    }
    
    func replaceCharacters(in range: NSRange, with aString: String) {
        imp.replaceCharacters(in: range, with: aString)
    }
    
    // MARK: - Code Intelligence
    
    func enumerateCode(in range: NSRange, usingBlock block: @escaping (_ range: NSRange, _ type: CodeType) -> Void) {
        assert(NSEqualRanges(range, paragraphRange(for: range)), "Invalid parameter not satisfying: NSEqualRanges(range, paragraphRange(for: range))")
        // Enumerate lines
        enumerateSubstrings(in: range, options: .byParagraphs, using: { [unowned self] paragraph, substringRange, enclosingRange, stop in
            // detect comments
            if (paragraph!.trimmingCharacters(in: .whitespaces).hasPrefix("//")) {
                block(enclosingRange, .Comment)
                return
            }
            
            // detect comments
            if (paragraph!.hasPrefix("#")) {
                block(enclosingRange, .Comment)
                return
            }
            
            // Detect keywords
            enumerateSubstrings(in: enclosingRange, options: .byWords, using: { word, innerSubstringRange, innerEnclosingRange, stop in
                // Substring is a keyword
                if ["int", "const", "char", "return"].contains(word) {
                    // Text before keyword is just text
                    if innerEnclosingRange.location < innerSubstringRange.location {
                        block(NSMakeRange(innerEnclosingRange.location, innerSubstringRange.location - innerEnclosingRange.location), .Text)
                    }
                    // Keyword is a keyword
                    block(innerSubstringRange, .Keyword)
                    // Text behind keyword is just text
                    if NSMaxRange(innerEnclosingRange) > NSMaxRange(innerSubstringRange) {
                        block(NSMakeRange(NSMaxRange(innerSubstringRange), NSMaxRange(innerEnclosingRange) - NSMaxRange(innerSubstringRange)), .Text)
                    }
                } else {
                    block(innerEnclosingRange, .Text)
                }
            })
        })
    }

    func paragraphNumberForParagraph(at index: Int) -> Int {
        // WARNING: extremely inefficient implementation, should better be cached
        var number = 1
        enumerateSubstrings(in: NSMakeRange(0, index), options: [.byParagraphs, .substringNotRequired], using: { substring, substringRange, enclosingRange, stop in
            number += 1
        })
        return number
    }
}
