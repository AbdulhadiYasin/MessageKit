/*
 MIT License

 Copyright (c) 2017-2019 MessageKit

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 */

import Foundation
import UIKit

open class TextMessageSizeCalculator: MessageSizeCalculator {

    public var incomingMessageLabelInsets = UIEdgeInsets(top: 7, left: 18, bottom: 7, right: 14)
    public var outgoingMessageLabelInsets = UIEdgeInsets(top: 7, left: 14, bottom: 7, right: 18)

    public var messageLabelFont = UIFont.preferredFont(forTextStyle: .body)

    internal func messageLabelInsets(for message: MessageType) -> UIEdgeInsets {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingMessageLabelInsets : incomingMessageLabelInsets
    }

    open override func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        let maxWidth = super.messageContainerMaxWidth(for: message)
        let textInsets = messageLabelInsets(for: message)
        let containerInsets = messageContainerInsets(for: message)
        return maxWidth - textInsets.horizontal - containerInsets.horizontal
    }

    open override func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let maxWidth = messageContainerMaxWidth(for: message)

        var messageContainerSize: CGSize
        var attributedText: NSAttributedString

        let textMessageKind = message.kind.textMessageKind
        switch textMessageKind {
        case .attributedText(let text):
            attributedText = text
        case .text(let text), .emoji(let text):
            attributedText = NSAttributedString(string: text, attributes: [.font: messageLabelFont])
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
        
        let topLabelPosition = messageTopLabelPosition(for: message);
        let bottomLabelPosition = messageBottomLabelPosition(for: message);
        
        // When top/bottom labels possition is inline we can assume that it's legal
        // and makes sense to the layout.
        attributedText = self.inlineMessageText(
            message: message, at: indexPath, attributedText: attributedText, maxWidth: maxWidth,
            topLabel: topLabelPosition, bottomLabel: bottomLabelPosition)
        

        messageContainerSize = labelSize(for: attributedText, considering: maxWidth)
        let baseHeight = messageContainerSize.height;

        let messageInsets = messageLabelInsets(for: message)
        let containerInsets = messageContainerInsets(for: message)
        
        messageContainerSize.width += messageInsets.horizontal + containerInsets.horizontal
        messageContainerSize.height += messageInsets.vertical + containerInsets.vertical;
        
        if topLabelPosition == .inline {
            // #1.0. By default a space for the top label is reserved, but container's
            // background streches underneath it to mimic thats it's contained
            // within the message container itself.
            //
            // #1.1 to acheive an inline top label we will reduce this reserved height
            // of the top label, strech the background underneath it and start
            // message's content at the start of the top label but with a horizontal
            // spacing to avoid overlapping.
            messageContainerSize.height -= messageTopLabelSize(for: message, at: indexPath).height
        }
        
        if bottomLabelPosition == .inline {
            // #2.0. Look at comment #1.0.
            messageContainerSize.height -= messageBottomLabelSize(for: message, at: indexPath).height
        }
        
        let minSize = messageContainerMinSize(for: message, at: indexPath)
        let width = max(minSize.width, messageContainerSize.width);
        
        if topLabelPosition == .inline && bottomLabelPosition == .inline && attributedText.numberOfLines(with: width) == 1 {
            let t = messageTopLabelSize(for: message, at: indexPath).height;
            let b = messageBottomLabelSize(for: message, at: indexPath).height;
            messageContainerSize.height = (baseHeight - t - b) + containerInsets.vertical;
        }

        return CGSize(width: width, height: messageContainerSize.height)
    }
    
    open override func canUseInlineMessageTopLabel(for message: MessageType) -> Bool {
        guard let string = text(for: message), !string.isEmpty else {
            return super.canUseInlineMessageTopLabel(for: message)
        }
        
        return netMessageTopLabelAlignment(for: message).textAlignment == (string.isRTL ? .right : .left);
    }
    
    open override func canUseInlineMessageBottomLabel(for message: MessageType) -> Bool {
        guard let string = text(for: message), !string.isEmpty else {
            return super.canUseInlineMessageBottomLabel(for: message)
        }
        
        return netMessageBottomLabelAlignment(for: message).textAlignment == (string.isRTL ? .left : .right);
    }
    
    /// Returns text (string) value of message content (stripped of attributes if there's any).
    open func text(for message: MessageType) -> String? {
        switch message.kind.textMessageKind {
        case .text(let text), .emoji(let text):
            return text;
        case .attributedText(let text):
            return text.string;
        default:
            return nil
        }
    }
    
    /// Returns message's text content adjusted for inline top/bottom message labels.
    internal func inlineMessageText(
        message: MessageType, at indexPath: IndexPath, attributedText: NSAttributedString, maxWidth: CGFloat, spacing: CGFloat? = nil,
        topLabel: MessageLabelPosition, bottomLabel: MessageLabelPosition) -> NSAttributedString{
        guard topLabel == .inline || bottomLabel == .inline else { return attributedText; }
        
        let attributedString = NSMutableAttributedString(attributedString: attributedText);
        
        let dataSource = messagesLayout.messagesDataSource;
        if topLabel == .inline, let topLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath){
            
            let font = topLblTxt.font(at: topLblTxt.length - 1) ?? attributedString.font(at: 0)
            let spacing = spacing ?? (font != nil ? self.spacing(for:  font!) : 8);
            
            // Calculate horizontal spacing needed to avoid overlapping with
            // message's top label.
            let textAlignment = netMessageTopLabelAlignment(for: message);
            let labelWidth = maxWidth - textAlignment.textInsets.horizontal;
            let frame = topLblTxt.lastLineFrame(labelWidth: labelWidth)
            let _height = attributedString.newLineHeight(
                forSpacing: frame.width+spacing, at: 0, labelWidth: labelWidth) ?? frame.height;
            
            attributedString.addSpacing(
                width: frame.width + spacing, at: 0, height: min(frame.height, _height),
                labelWidth: labelWidth);
        }
        
        if bottomLabel == .inline, let btmLblTxt = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath){
            
            // Calculate font spacing.
            let font = btmLblTxt.font(at: 0) ?? attributedString.font(at: attributedString.length - 1)
            let spacing = spacing ?? (font != nil ? self.spacing(for:  font!) : 8);
            
            // Calculate horizontal spacing needed to avoid overlapping with
            // message's bottom label.
            let textAlignment = netMessageBottomLabelAlignment(for: message);
            let labelWidth = maxWidth - textAlignment.textInsets.horizontal;
            let frame = btmLblTxt.firstLineFrame(labelWidth: labelWidth)
            let _height = attributedString.newLineHeight(
                forSpacing: frame.width+spacing, at: attributedString.length,
                labelWidth: labelWidth) ?? frame.height;
            
            attributedString.addSpacing(
                width: frame.width + spacing, at: attributedString.length,
                height: min(frame.height, _height), labelWidth: labelWidth);
        }
        
        return attributedString;
    }
    
    private func spacing(for font: UIFont, maxWidth: CGFloat = .greatestFiniteMagnitude) -> CGFloat {
        return self.labelSize(for: .init(string: " ", attributes: [
            .font: font
        ]), considering: maxWidth).width;
    }
    
    
    

    open override func configure(attributes: UICollectionViewLayoutAttributes) {
        super.configure(attributes: attributes)
        guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

        let dataSource = messagesLayout.messagesDataSource
        let indexPath = attributes.indexPath
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)

        attributes.messageLabelInsets = messageLabelInsets(for: message)
        attributes.messageLabelFont = messageLabelFont

        switch message.kind {
        case .attributedText(let text):
            guard !text.string.isEmpty else { return }
            guard let font = text.attribute(.font, at: 0, effectiveRange: nil) as? UIFont else { return }
            attributes.messageLabelFont = font
        default:
            break
        }
    }
}

func boundingSize(_ lhs: CGSize, _ rhs: CGSize) -> CGSize {
    return CGSize(width: max(lhs.width, rhs.width), height: max(lhs.height, rhs.height))
}


extension NSAttributedString {

    
    func layoutManager<T>(width: CGFloat, _ handler: ((NSLayoutManager, NSTextContainer)->T)) -> T {
        
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let labelSize = CGSize(width: width, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: self)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0
        
        return handler(layoutManager, textContainer);
    }
    
    func lineFragmentUsedRect(at index: Int, labelWidth: CGFloat, effectiveRange: NSRangePointer? = nil, useFontHeight: Bool = true) -> CGRect {
        guard index >= 0 && index <= self.length else {
            return .zero;
        }
        
        // Create instances of NSLayoutManager, NSTextContainer and NSTextStorage
        let labelSize = CGSize(width: labelWidth, height: .infinity)
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: labelSize)
        let textStorage = NSTextStorage(attributedString: self)

        // Configure layoutManager and textStorage
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)

        // Configure textContainer
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = .byWordWrapping
        textContainer.maximumNumberOfLines = 0

        let glyphIndex = layoutManager.glyphIndexForCharacter(at: index)
        var lineFragmentRect = layoutManager
            .lineFragmentUsedRect(forGlyphAt: glyphIndex, effectiveRange: effectiveRange)
        
        if effectiveRange != nil {
            let r = layoutManager.characterRange(forGlyphRange: effectiveRange!.pointee, actualGlyphRange: nil)
            effectiveRange?.pointee = r;
        }
        
        if useFontHeight, let font = font(at: index){
            lineFragmentRect.size.height = font.lineHeight;
        }
        return lineFragmentRect
    }
    
    func boundingRect(forCharacterRange range: NSRange, labelWidth: CGFloat) -> CGRect? {
        layoutManager(width: labelWidth) {
            var glyphRange = NSRange();
            
            // Convert the range for glyphs.
            $0.characterRange(forGlyphRange: range, actualGlyphRange: &glyphRange)
            return $0.boundingRect(forGlyphRange: glyphRange, in: $1)
        }
    }
    
    func origin(forCharacterAt index: Int, labelWidth: CGFloat) -> CGPoint {
        return layoutManager(width: labelWidth) { (layout, _) in
            return layout.location(forGlyphAt: index);
        }
    }
    
    
    
    
    
    func lastLineFrame(labelWidth: CGFloat) -> CGRect {
        return self.lineFragmentUsedRect(at: self.length - 1, labelWidth: labelWidth)
    }
    
    func lastLineMaxX(labelWidth: CGFloat) -> CGFloat {
        return self.lastLineFrame(labelWidth: labelWidth).maxX
    }
    
    func firstLineFrame(labelWidth: CGFloat) -> CGRect {
        return self.lineFragmentUsedRect(at: 0, labelWidth: labelWidth);
    }
    
    func font(at index: Int) -> UIFont? {
        return attribute(.font, at: index, effectiveRange: nil) as? UIFont
    }
    
    func numberOfLines(with width: CGFloat) -> Int {
        
        let path = UIBezierPath(rect: CGRect(x: 0, y: 0, width: width, height: CGFloat(MAXFLOAT)))
        let frameSetterRef : CTFramesetter = CTFramesetterCreateWithAttributedString(self as CFAttributedString)
        let frameRef: CTFrame = CTFramesetterCreateFrame(frameSetterRef, CFRangeMake(0, 0), path.cgPath, nil)
        
        let linesNS: NSArray  = CTFrameGetLines(frameRef)
        
        guard let lines = linesNS as? [CTLine] else { return 0 }
        return lines.count
    }
    
    func newLineHeight(forSpacing spacing: CGFloat, at index: Int,
                       labelWidth: CGFloat) -> CGFloat? {
        let i = min(max(0, index), length - 1);
        guard let font = self.font(at: i) else { return nil; }
        
        if spacing >= labelWidth || self.length == 0 {
            // Spacing will take a full line.
            return font.lineHeight;
        }
        
        var lineRange: NSRange = NSRange(location: 0, length: 1);
        let lineWidth = lineFragmentUsedRect(at: i, labelWidth: labelWidth, effectiveRange: &lineRange).width;
        
        //print("lineRange: \(lineRange), substring: `\(self.substring(from: lineRange.lowerBound, to: lineRange.upperBound))`")
        if labelWidth - lineWidth >= spacing {
            // There's enough space within the line to include the spacing.
            return font.capHeight;
        }
        
        
        let startRange = NSRange(location: lineRange.location, length: i - lineRange.location)
        let startText = startRange.length > 0 ? self.attributedSubstring(from: startRange) : nil;
        let startWidth = startText?.firstLineFrame(labelWidth: labelWidth).width ?? 0;
        
        
        if lineWidth - startWidth >= spacing {
            // Theres's enough space to add spacing in line.
            // ...
            
            if startWidth > 0 {
                return font.capHeight;
            }
            
            // Adding spacing at start of line. Should check if there's text after
            // spacing within line.
            var endRange = NSRange(location: i, length: 0);
            for indx in i ... lineRange.upperBound {
                let char = self[indx];
                if char == " " || char == "\r" || char == "\n" {
                    break;
                }
                endRange.length += 1;
            }
            
            let endText = self.attributedSubstring(from: endRange);
            let endWidth = endText.firstLineFrame(labelWidth: labelWidth).width;
            
            if lineWidth-spacing-startWidth >= endWidth {
                // There's enough space to add end-text after spacing.
                return font.capHeight;
            }
            
            return font.lineHeight;
            
        } else {
            // Spacing should be added within a line on it's own.
            return font.lineHeight;
        }
    }

}

extension NSAttributedString {
    
    subscript (i: Int) -> String {
        return self[i ..< i + 1]
    }
    
    func substring(fromIndex: Int) -> String {
        return self[min(fromIndex, length) ..< length]
    }
    
    func substring(toIndex: Int) -> String {
        return self[0 ..< max(0, toIndex)]
    }
    
    func substring(from startIndex: Int, to endIndex: Int) -> String {
        guard let range = Range<Int>(NSRange(location: startIndex, length: endIndex-startIndex)) else {
            return "";
        }
        return self[range];
    }
    
    subscript (r: Range<Int>) -> String {
        let range = Range(uncheckedBounds: (lower: max(0, min(length, r.lowerBound)),
                                            upper: min(length, max(0, r.upperBound))))
        let start = string.index(string.startIndex, offsetBy: range.lowerBound)
        let end = string.index(start, offsetBy: range.upperBound - range.lowerBound)
        return String(self.string[start ..< end])
    }
}

extension NSMutableAttributedString {
    
    func addFirstLineHeadIndent(_ width: CGFloat){
        let p = NSMutableParagraphStyle();
        p.firstLineHeadIndent = width;
        
        addAttributes([.paragraphStyle: p], range: NSRange(location: 0, length: length))
    }
    
    func addSpacing(width: CGFloat, at index: Int, height: CGFloat? = nil, labelWidth: CGFloat? = nil){
        let i = min(max(0, index), length - 1);
        var _height = height ?? 0.0001;
        if height == nil, font(at: i) != nil, let labelWidth = labelWidth,
           let h = self.newLineHeight(forSpacing: width, at: index, labelWidth: labelWidth) {
            _height = h
        }
        let image5Attachment = NSTextAttachment()
        image5Attachment.image = /*UIImage.imageWithColor(color: UIColor.green.withAlphaComponent(0.5)) ??*/ UIImage();
        image5Attachment.bounds = CGRect.init(x: 0, y: 0, width: width, height: _height)
        // wrap the attachment in its own attributed string so we can append it
        let imageSpaceHorizontal = NSMutableAttributedString(attachment: image5Attachment);
        
        let attrs = attributes(at: min(max(0, index), length - 1), effectiveRange: nil)
        imageSpaceHorizontal.addAttributes(attrs, range: NSRange(location: 0, length: imageSpaceHorizontal.length))
        
        self.insert(imageSpaceHorizontal, at: index);
    }
    
    func setTextAlignment(_ textAlignment: NSTextAlignment){
        let p = NSMutableParagraphStyle();
        p.alignment = textAlignment;
        addAttribute(.paragraphStyle, value: p, range: _NSRange(location: 0, length: length))
    }
}

fileprivate extension UIImage {
    class func imageWithColor(color: UIColor, size: CGSize=CGSize(width: 1, height: 1)) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: CGPoint.zero, size: size))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
