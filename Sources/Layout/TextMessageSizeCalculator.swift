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
            message: message, at: indexPath, attributedText: attributedText,
            maxWidth: maxWidth, spacing: 0,
            topLabel: topLabelPosition, bottomLabel: bottomLabelPosition)
        

        messageContainerSize = labelSize(for: attributedText, considering: maxWidth)

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
        return CGSize(width: max(minSize.width, messageContainerSize.width), height: messageContainerSize.height)
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
        
        return netMessageTopLabelAlignment(for: message).textAlignment == (string.isRTL ? .left : .right);
    }
    
    private func text(for message: MessageType) -> String? {
        switch message.kind {
        case .text(let text), .emoji(let text): return text;
        case .attributedText(let text): return text.string;
        case .linkPreview(let linkItem):
            if let text = linkItem.text {
                return text
            } else if let attributedText = linkItem.attributedText {
                return attributedText.string
            }
            return nil;
        default:
            return nil
        }
    }
    
    private func inlineMessageText(
        message: MessageType, at indexPath: IndexPath, attributedText: NSAttributedString, maxWidth: CGFloat, spacing: CGFloat = 8.0,
        topLabel: MessageLabelPosition, bottomLabel: MessageLabelPosition) -> NSAttributedString{
        guard topLabel == .inline || bottomLabel == .inline else { return attributedText; }
        
        let attributedString = NSMutableAttributedString(attributedString: attributedText);
        
        let dataSource = messagesLayout.messagesDataSource;
        if topLabel == .inline, let topLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath){
            
            // Calculate horizontal spacing needed to avoid overlapping with
            // message's top label.
            let textAlignment = netMessageTopLabelAlignment(for: message);
            let frame = topLblTxt.lastLineFrame(labelWidth: maxWidth - textAlignment.textInsets.horizontal)
            
            attributedString.addSpacing(width: textAlignment.textInsets.left + frame.maxX + spacing, at: 0);
        }
        
        if bottomLabel == .inline, let btmLblTxt = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath){
            // Calculate horizontal spacing needed to avoid overlapping with
            // message's bottom label.
            let textAlignment = netMessageBottomLabelAlignment(for: message);
            let frame = btmLblTxt.firstLineFrame(labelWidth: maxWidth - textAlignment.textInsets.horizontal)
            
            attributedString.addSpacing(width: frame.width, at: attributedString.length);
        }
        
        return attributedString;
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

    func lineFragmentUsedRect(at index: Int, labelWidth: CGFloat) -> CGRect {
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
        let lineFragmentRect = layoutManager.lineFragmentUsedRect(forGlyphAt: glyphIndex,
                                                                      effectiveRange: nil)
        
        return lineFragmentRect
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
}

extension NSMutableAttributedString {
    
    func addFirstLineHeadIndent(_ width: CGFloat){
        let p = NSMutableParagraphStyle();
        p.firstLineHeadIndent = width;
        
        addAttributes([.paragraphStyle: p], range: NSRange(location: 0, length: string.count))
    }
    
    func addSpacing(width: CGFloat, at index: Int, height: CGFloat = 0.0001){
        let image5Attachment = NSTextAttachment()
        image5Attachment.image = UIImage()
        image5Attachment.bounds = CGRect.init(x: 0, y: -5, width: width, height: height)
        // wrap the attachment in its own attributed string so we can append it
        let imageSpaceHorizontal = NSAttributedString(attachment: image5Attachment)
        
        self.insert(imageSpaceHorizontal, at: index);
    }
}
