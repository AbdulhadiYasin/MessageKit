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
        let attributedText: NSAttributedString = attributedString(for: message, at: indexPath)

        /*let textMessageKind = attributedString(for: message, at: indexPath) message.kind.textMessageKind
        switch textMessageKind {
        case .attributedText(let text):
            attributedText = text
        case .text(let text), .emoji(let text):
            attributedText = NSAttributedString(string: text, attributes: [.font: messageLabelFont])
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }*/

        messageContainerSize = labelSize(for: attributedText, considering: maxWidth)

        let messageInsets = messageLabelInsets(for: message)
        let containerInsets = messageContainerInsets(for: message)
        
        messageContainerSize.width += messageInsets.horizontal + containerInsets.horizontal
        messageContainerSize.height += messageInsets.vertical + containerInsets.vertical;

        let minSize = messageContainerMinSize(for: message, at: indexPath)
        return CGSize(width: max(minSize.width, messageContainerSize.width), height: messageContainerSize.height)
    }
    
    private func attributedString(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString {
        let textMessageKind = message.kind.textMessageKind
        var attributedText: NSMutableAttributedString
        
        switch textMessageKind {
        case .attributedText(let text):
            attributedText = NSMutableAttributedString(attributedString: text)
        case .text(let text), .emoji(let text):
            attributedText = NSAttributedString(string: text, attributes: [.font: messageLabelFont]) as! NSMutableAttributedString
        default:
            fatalError("messageContainerSize received unhandled MessageDataType: \(message.kind)")
        }
        
        let dataSource = messagesLayout.messagesDataSource;
        let maxWidth = messageContainerMaxWidth(for: message);
        
        if messageBottomLabelPosition(for: message) == .inline {
            let alignment = self.netMessageBottomLabelAlignment(for: message);
            switch alignment.textAlignment {
            case .right:
                if let btmLblTxt = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath) {
                    let attachment = NSTextAttachment()
                    let lblSze = labelSize(for: btmLblTxt, considering: maxWidth);
                    attachment.bounds = CGRect(origin: .zero, size: lblSze)
                    attributedText.insert(NSAttributedString(attachment: attachment), at: attributedText.string.count)
                }
                break;
            default:
                break;
            }
        }
        
        if messageTopLabelPosition(for: message) == .inline {
            let alignment = self.netMessageTopLabelAlignment(for: message);
            switch alignment.textAlignment {
            case .left:
                if let tpLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath) {
                    let attachment = NSTextAttachment()
                    let lblSze = labelSize(for: tpLblTxt, considering: maxWidth);
                    attachment.bounds = CGRect(origin: .zero, size: lblSze)
                    attributedText.insert(NSAttributedString(attachment: attachment), at: 0)
                }
                break;
            default:
                break;
            }
        }
        
        return attributedText;
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
