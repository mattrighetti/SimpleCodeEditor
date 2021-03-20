//
//  TKETextContainer.swift
//  TextKitEditor
//
//  Created by Mattia Righetti on 20/03/21.
//

import Foundation
import UIKit

class TextContainer: NSTextContainer {
    override func lineFragmentRect(forProposedRect proposedRect: CGRect, at characterIndex: Int, writingDirection baseWritingDirection: NSWritingDirection, remaining remainingRect: UnsafeMutablePointer<CGRect>?) -> CGRect {
        var rect = super.lineFragmentRect(forProposedRect: proposedRect, at: characterIndex, writingDirection: baseWritingDirection, remaining: remainingRect)
        // IMPORTANT: Inset width only, since setting a non-zero X coordinate kills the text system
        // Offset must be done *after layout computation* in UMLayoutManager's -setLineFragmentRect:forGlyphRange:usedRect:
        let insets = (layoutManager as! LayoutManager).insetsForLineStarting(atCharacterIndex: characterIndex)
        rect.size.width -= (insets.left) + (insets.right)
        return rect
    }
}
