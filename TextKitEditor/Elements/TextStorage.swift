//
//  TKETextStorage.swift
//  TextKitEditor
//
//  Created by Mattia Righetti on 20/03/21.
//

import Foundation
import UIKit

class TextStorage: NSTextStorage {
    var cache: NSMutableAttributedString
    
    override init() {
        cache = NSMutableAttributedString()
        super.init()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Accessors
    
    var content: CodeString! {
        didSet {
            // Coalesce chage notification
            beginEditing()
            // re-build string cache
            let oldLength = cache.length
            cache.replaceCharacters(in: NSMakeRange(0, oldLength), with: content as String)
            edited(.editedCharacters, range: NSMakeRange(0, oldLength), changeInLength: content.length - oldLength)
            // re-evaluate attributes
            updateAttributesForChangeRange(range: NSMakeRange(0, content.length))
            // end coalesce change
            endEditing()
        }
    }
    
    var font: UIFont = UIFont(name: "Menlo", size: 13)! {
        didSet {
            // re-compute attributes
            beginEditing()
            updateAttributesForChangeRange(range: NSMakeRange(0, content.length))
            endEditing()
        }
    }
    
    func paragraphNumberForParagraph(at index: Int) -> Int {
        // simple forward here. But since only the text storage "knows" about the mapping from content to cache (1:1) we better loop it through here.
        content.paragraphNumberForParagraph(at: index)
    }
    
    // MARK: - Text Storage Accessors
    
    override var string: String {
        cache.string
    }
    
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        cache.attributes(at: location, effectiveRange: range)
    }
    
    override func replaceCharacters(in range: NSRange, with str: String) {
        // update content and cache -- attributes will be re-computed later
        self.content.replaceCharacters(in: range, with: str)
        cache.replaceCharacters(in: range, with: str)
        // notify textual change
        edited(.editedCharacters, range: range, changeInLength: str.count - range.length)
    }
    
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        // update cache with new attributes only
        cache.setAttributes(attrs, range: range)
        // notify attribute change
        edited(.editedAttributes, range: range, changeInLength: 0)
    }
    
    // MARK: - Attribute Computation
    
    override func processEditing() {
        // Text has been changed in content and cache, now update the text colors as well
        updateAttributesForChangeRange(range: editedRange)
        // Call super *after* changing the attributes, as it finalizes the attributes and calls the delegate methods.
        super.processEditing()
    }
    
    func textColorFor(_ type: CodeType) -> UIColor {
        switch (type) {
        case .Text:
            return UIColor.black
        case .Comment:
            return UIColor.green
        case .Pragma:
            return UIColor.orange
        case .Keyword:
            return UIColor.blue
        }
    }
    
    func updateAttributesForChangeRange(range: NSRange) {
        // always recompute complete paragraphs, the string requires us to
        let range = content.paragraphRange(for: range)
        // clear all content attributes
        setAttributes([:], range: range)
        // set font attribute
        addAttribute(.font, value: font, range: range)
        // enumerate code types in range
        content.enumerateCode(in: range) { [unowned self] range, type in
            // text color depends on type
            addAttribute(.foregroundColor, value: self.textColorFor(type), range: range)
        }
    }
}
