//
//  TKELayoutManager.swift
//  TextKitEditor
//
//  Created by Mattia Righetti on 20/03/21.
//

import Foundation
import UIKit

class LayoutManager: NSLayoutManager, NSLayoutManagerDelegate {
    // MARK: - Layout Properties
    var showParagraphNumbers: Bool {
        didSet {
            self.invalidateLayout(forCharacterRange: NSMakeRange(0, self.textStorage!.length), actualCharacterRange: nil)
        }
    }
    
    var tabWidth: Int {
        didSet {
            self.invalidateLayout(forCharacterRange: NSMakeRange(0, self.textStorage!.length), actualCharacterRange: nil)
        }
    }
    
    var lineHeight: Int {
        didSet {
            self.invalidateLayout(forCharacterRange: NSMakeRange(0, self.textStorage!.length), actualCharacterRange: nil)
        }
    }
    
    override init() {
        self.showParagraphNumbers = false
        self.tabWidth = 2
        self.lineHeight = 1
        super.init()
        self.delegate = self
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Layout Computation
    
    func insetsForLineStarting(atCharacterIndex characterIndex: Int) -> UIEdgeInsets {
        var leftInset: CGFloat = 0

        // Base inset when showing paragraph numbers
        if showParagraphNumbers {
            leftInset += 16
        }

        // For wrapped lines, determine where line is supposed to start
        let paragraphRange = (textStorage?.string as NSString?)!.paragraphRange(for: NSRange(location: characterIndex, length: 0))
        if (paragraphRange.location) < characterIndex {
            // Get the first glyph index in the paragraph
            let firstGlyphIndex = glyphIndexForCharacter(at: paragraphRange.location)

            // Get the first line of the paragraph
            var firstLineGlyphRange: NSRange = NSRange()
            lineFragmentRect(forGlyphAt: firstGlyphIndex, effectiveRange: &firstLineGlyphRange)
            let firstLineCharRange = characterRange(forGlyphRange: firstLineGlyphRange, actualGlyphRange: nil)

            // Find the first wrapping char (here we use brackets), and wrap one char behind
            var wrappingCharIndex = NSNotFound
            wrappingCharIndex = ((textStorage?.string as NSString?)!.rangeOfCharacter(from: CharacterSet(charactersIn: "({["), options: [], range: firstLineCharRange).location)
            if wrappingCharIndex != NSNotFound {
                wrappingCharIndex += 1
            }
            
            // Alternatively, fall back to the first text (ie. non-whitespace) char
            if wrappingCharIndex == NSNotFound {
                wrappingCharIndex = (textStorage?.string as NSString?)!.rangeOfCharacter(from: CharacterSet.whitespaces.inverted, options: [], range: firstLineCharRange).location
                if wrappingCharIndex != NSNotFound {
                    wrappingCharIndex += 4
                }
            }

            // Wrapping char found, determine indent
            if wrappingCharIndex != NSNotFound {
                let firstTextGlyphIndex = glyphIndexForCharacter(at: wrappingCharIndex)

                // The additional indent is the distance from the first to the last character
                leftInset += location(forGlyphAt: firstTextGlyphIndex).x - location(forGlyphAt: firstGlyphIndex).x
            }
        }

        // For now we compute left insets only, but rigth inset is also possible
        return UIEdgeInsets(top: 0, left: leftInset, bottom: 0, right: 0)
    }
    
    // MARK: - Layout Handling
    
    func layoutManager(_ layoutManager: NSLayoutManager, lineSpacingAfterGlyphAt glyphIndex: Int, withProposedLineFragmentRect rect: CGRect) -> CGFloat {
        // line height is a multiple og th ecomplete line, here we neeed only the extra space
        return CGFloat((max(lineHeight, 1) - 1)) * rect.size.height
    }
    
    override func setLineFragmentRect(_ fragmentRect: CGRect, forGlyphRange glyphRange: NSRange, usedRect: CGRect) {
        let insets = insetsForLineStarting(atCharacterIndex: self.characterIndexForGlyph(at: glyphRange.location))
        var newFragmentRect = fragmentRect
        var newUsedRect = usedRect
        newFragmentRect.origin.x += insets.left
        newUsedRect.origin.x += insets.left
        super.setLineFragmentRect(newFragmentRect, forGlyphRange: glyphRange, usedRect: newUsedRect)
    }
    
    override func setExtraLineFragmentRect(_ fragmentRect: CGRect, usedRect: CGRect, textContainer container: NSTextContainer) {
        let insets = insetsForLineStarting(atCharacterIndex: self.textStorage!.length)
        var newFragmentRect = fragmentRect
        var newUsedRect = usedRect
        newFragmentRect.origin.x += insets.left
        newUsedRect.origin.x += insets.left
        super.setExtraLineFragmentRect(newFragmentRect, usedRect: newUsedRect, textContainer: container)
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, shouldUse action: NSLayoutManager.ControlCharacterAction, forControlCharacterAt charIndex: Int) -> NSLayoutManager.ControlCharacterAction {
        // we want to adjust the positions for the tab characters
        // TODO could be incorrect to use uint16 directly
        if ((self.textStorage!.string as NSString).character(at: charIndex) == UInt16("\t")) {
            return .whitespace
        }
        
        return action
    }
    
    func layoutManager(_ layoutManager: NSLayoutManager, boundingBoxForControlGlyphAt glyphIndex: Int, for textContainer: NSTextContainer, proposedLineFragment proposedRect: CGRect, glyphPosition: CGPoint, characterIndex charIndex: Int) -> CGRect {
        let primaryFont = (self.textStorage as! TextStorage).font
        let nWidth = "n".boundingRect(with: CGSize(width: 1000, height: 1000), options: [], attributes: [
            NSAttributedString.Key.font: primaryFont as Any
        ], context: nil).size.width
        let tabSize = nWidth * CGFloat(self.tabWidth)
        let tabPosition = floor((glyphPosition.x + nWidth/2) / tabSize + 1) * tabSize
        var rect = CGRect()
        rect.origin = glyphPosition
        rect.size.width = tabPosition - glyphPosition.x
        return rect
    }
    
    // MARK: - Drawing
    
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
        // Draw paragraph numbers if enabled
        if showParagraphNumbers {
            drawParagraphNumbers(forGlyphRange: glyphsToShow, at: origin)
        }
    }

    func drawParagraphNumbers(forGlyphRange glyphRange: NSRange, at origin: CGPoint) {
        // Enumerate all lines
        var glyphIndex = glyphRange.location
        while glyphIndex < NSMaxRange(glyphRange) {
            var glyphLineRange: NSRange = NSRange()
            let lineFragmentRect = self.lineFragmentRect(forGlyphAt: glyphIndex, effectiveRange: &glyphLineRange)
            // Check for paragraph start
            let lineRange = characterRange(forGlyphRange: glyphLineRange, actualGlyphRange: nil)
            let paragraphRange = (textStorage?.string as NSString?)!.paragraphRange(for: lineRange)
            // Draw paragraph number if we're at the start of a paragraph
            if lineRange.location == paragraphRange.location {
                drawParagraphNumber(forCharRange: paragraphRange, lineFragmentRect: lineFragmentRect, at: origin)
            }
            // Advance
            glyphIndex = NSMaxRange(glyphLineRange)
        }
    }
    
    func drawParagraphNumber(forCharRange charRange: NSRange, lineFragmentRect lineRect: CGRect, at origin: CGPoint) {
        // Get number of paragraph
        let paragraphNumber = (textStorage as? TextStorage)?.paragraphNumberForParagraph(at: charRange.location) ?? 0
        // Prepare rendering attributes -- get string, attribute and size
        let numberString = String(format: "%lu", paragraphNumber)
        let attributes = [
            NSAttributedString.Key.foregroundColor: UIColor(white: 0.3, alpha: 1),
            NSAttributedString.Key.font: UIFont.systemFont(ofSize: 9)
        ]
        let height = numberString.boundingRect(with: CGSize(width: 1000, height: 1000), options: [], attributes: attributes, context: nil).size.height
        // Rect for number to be drawn into
        var numberRect = CGRect()
        numberRect.size.width = lineRect.origin.x
        numberRect.origin.x = origin.x
        numberRect.size.height = height
        numberRect.origin.y = lineRect.midY - height * 0.5 + origin.y
        // Actual drawing of paragroh number
        numberString.draw(with: numberRect, options: .usesLineFragmentOrigin, attributes: attributes, context: nil)
    }
}
