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

import UIKit

/// A subclass of `MessageContentCell` used to display text messages.
open class TextMessageCell: MessageContentCell {

    // MARK: - Properties

    /// The `MessageCellDelegate` for the cell.
    open override weak var delegate: MessageCellDelegate? {
        didSet {
            messageLabel.delegate = delegate
        }
    }

    /// The label used to display the message's text.
    open var messageLabel = MessageLabel()

    // MARK: - Methods

    open override func apply(_ layoutAttributes: UICollectionViewLayoutAttributes) {
        super.apply(layoutAttributes)
        if let attributes = layoutAttributes as? MessagesCollectionViewLayoutAttributes {
            messageLabel.textInsets = attributes.messageLabelInsets
            messageLabel.messageLabelFont = attributes.messageLabelFont
            
            var safeArea = attributes.messageContainerSafeaAreaInsets
            if attributes.messageTopLabelPosition == .inline {
                safeArea.top -= attributes.messageTopLabelSize.height
            }
            if attributes.messageBottomLabelPosition == .inline {
                safeArea.bottom -= attributes.messageBottomLabelSize.height
            }
            
            messageLabel.frame = messageContainerView.bounds.inset(by: safeArea)
            //messageLabel.frame = messageContainerView.bounds
        }
    }

    open override func prepareForReuse() {
        super.prepareForReuse()
        messageLabel.attributedText = nil
        messageLabel.text = nil
    }

    open override func setupSubviews() {
        super.setupSubviews()
        messageContainerView.addSubview(messageLabel)
    }

    open override func configure(with message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) {
        super.configure(with: message, at: indexPath, and: messagesCollectionView)

        guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
            fatalError(MessageKitError.nilMessagesDisplayDelegate)
        }

        let enabledDetectors = displayDelegate.enabledDetectors(for: message, at: indexPath, in: messagesCollectionView)

        messageLabel.configure {
            messageLabel.enabledDetectors = enabledDetectors
            for detector in enabledDetectors {
                let attributes = displayDelegate.detectorAttributes(for: detector, and: message, at: indexPath)
                messageLabel.setAttributes(attributes, detector: detector)
            }
            let textMessageKind = message.kind.textMessageKind
            if let text = self.attributedText(for: message, at: indexPath, and: messagesCollectionView) {
                messageLabel.attributedText = text
            } else {
                switch textMessageKind {
                case .text(let text), .emoji(let text):
                    let textColor = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView)
                    messageLabel.text = text
                    messageLabel.textColor = textColor
                    if let font = messageLabel.messageLabelFont {
                        messageLabel.font = font
                    }
                case .attributedText(let text):
                    messageLabel.attributedText = text
                default:
                    break
                }
            }
        }
    }
    
    private func attributedText(for message: MessageType, at indexPath: IndexPath, and messagesCollectionView: MessagesCollectionView) -> NSAttributedString? {
        guard let dataSource = messagesCollectionView.messagesDataSource else {
            fatalError(MessageKitError.nilMessagesDataSource)
        }
        
        guard let sizeCalculator = messagesCollectionView.messagesCollectionViewFlowLayout.cellSizeCalculatorForItem(at: indexPath) as? MessageSizeCalculator else {
            return nil
        }
        
        let attributedText: NSMutableAttributedString
        switch message.kind.textMessageKind {
        case .text(let txt), .emoji(let txt):
            guard let displayDelegate = messagesCollectionView.messagesDisplayDelegate else {
                fatalError(MessageKitError.nilMessagesDisplayDelegate)
            }
            
            var attributes = [NSAttributedString.Key: Any]()
            attributes[.foregroundColor] = displayDelegate.textColor(for: message, at: indexPath, in: messagesCollectionView);
            attributes[.font] = messageLabel.messageLabelFont;
            attributedText = NSMutableAttributedString.init(string: txt, attributes: attributes)
            break
        case .attributedText(let attText):
            attributedText = NSMutableAttributedString(attributedString: attText)
            break
        default:
            return nil
        }
        
        let tpLblPstn = sizeCalculator.messageTopLabelPosition(for: message);
        let btmLblPstn = sizeCalculator.messageBottomLabelPosition(for: message);
        
        if tpLblPstn == .inline && messageTopLabel.textAlignment == .left,
           let tpLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath) {
            
            let alignment = sizeCalculator.netMessageTopLabelAlignment(for: message)
            let sze = sizeCalculator.labelSize(for: tpLblTxt, considering: messageContainerView.bounds.width - alignment.textInsets.horizontal)
            
            let font = self.messageTopLabel.font;
            let p = NSMutableParagraphStyle();
            p.firstLineHeadIndent = sze.width + 8;
            attributedText.addAttributes([.paragraphStyle: p], range: NSRange(location: 0, length: attributedText.string.count))
        }
        
        return attributedText
    }
    
    /// Used to handle the cell's contentView's tap gesture.
    /// Return false when the contentView does not need to handle the gesture.
    open override func cellContentView(canHandle touchPoint: CGPoint) -> Bool {
        return messageLabel.handleGesture(touchPoint)
    }

}
