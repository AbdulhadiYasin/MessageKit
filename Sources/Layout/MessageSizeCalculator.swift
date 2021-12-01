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

open class MessageSizeCalculator: CellSizeCalculator {

    public init(layout: MessagesCollectionViewFlowLayout? = nil) {
        super.init()
        
        self.layout = layout
    }

    public var incomingAvatarSize = CGSize(width: 30, height: 30)
    public var outgoingAvatarSize = CGSize(width: 30, height: 30)

    public var incomingAvatarPosition = AvatarPosition(vertical: .cellBottom)
    public var outgoingAvatarPosition = AvatarPosition(vertical: .cellBottom)

    public var avatarLeadingTrailingPadding: CGFloat = 0

    public var incomingMessagePadding = UIEdgeInsets(top: 0, left: 4, bottom: 0, right: 30)
    public var outgoingMessagePadding = UIEdgeInsets(top: 0, left: 30, bottom: 0, right: 4)
    
    public var incomingMessageContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    public var outgoingMessageContainerInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    public var incomingCellTopLabelAlignment = LabelAlignment(textAlignment: .center, textInsets: .zero)
    public var outgoingCellTopLabelAlignment = LabelAlignment(textAlignment: .center, textInsets: .zero)
    
    public var incomingCellBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
    public var outgoingCellBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

    public var incomingMessageTopLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
    public var outgoingMessageTopLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))

    public var incomingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .left, textInsets: UIEdgeInsets(left: 42))
    public var outgoingMessageBottomLabelAlignment = LabelAlignment(textAlignment: .right, textInsets: UIEdgeInsets(right: 42))
    
    public var incomingMessageTopLabelPosition = MessageLabelPosition.outter;
    public var outgoingMessageTopLabelPosition = MessageLabelPosition.outter;
     
    public var incomingMessageBottomLabelPosition = MessageLabelPosition.outter;
    public var outgoingMessageBottomLabelPosition = MessageLabelPosition.outter;

    public var incomingAccessoryViewSize = CGSize.zero
    public var outgoingAccessoryViewSize = CGSize.zero

    public var incomingAccessoryViewPadding = HorizontalEdgeInsets.zero
    public var outgoingAccessoryViewPadding = HorizontalEdgeInsets.zero
    
    public var incomingAccessoryViewPosition: AccessoryPosition = .messageCenter
    public var outgoingAccessoryViewPosition: AccessoryPosition = .messageCenter

    open override func configure(attributes: UICollectionViewLayoutAttributes) {
        guard let attributes = attributes as? MessagesCollectionViewLayoutAttributes else { return }

        let dataSource = messagesLayout.messagesDataSource
        let indexPath = attributes.indexPath
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)

        attributes.avatarSize = avatarSize(for: message)
        attributes.avatarPosition = avatarPosition(for: message)
        attributes.avatarLeadingTrailingPadding = avatarLeadingTrailingPadding

        attributes.messageContainerPadding = messageContainerPadding(for: message)
        attributes.messageContainerInsets = messageContainerInsets(for: message)
        attributes.messageContainerSize = messageContainerSize(for: message, at: indexPath)
        attributes.cellTopLabelSize = cellTopLabelSize(for: message, at: indexPath)
        attributes.cellTopLabelAlignment = cellTopLabelAlignment(for: message)
        attributes.cellBottomLabelSize = cellBottomLabelSize(for: message, at: indexPath)
        attributes.messageTimeLabelSize = messageTimeLabelSize(for: message, at: indexPath)
        attributes.cellBottomLabelAlignment = cellBottomLabelAlignment(for: message)
        
        attributes.messageTopLabelSize = messageTopLabelSize(for: message, at: indexPath)
        attributes.messageTopLabelAlignment = messageTopLabelAlignment(for: message, attributes: attributes)

        attributes.messageBottomLabelAlignment = messageBottomLabelAlignment(for: message, attributes: attributes)
        attributes.messageBottomLabelSize = messageBottomLabelSize(for: message, at: indexPath)
        
        attributes.messageTopLabelPosition = messageTopLabelPosition(for: message)
        attributes.messageBottomLabelPosition = messageBottomLabelPosition(for: message)

        attributes.accessoryViewSize = accessoryViewSize(for: message)
        attributes.accessoryViewPadding = accessoryViewPadding(for: message)
        attributes.accessoryViewPosition = accessoryViewPosition(for: message)
        
        attributes.messageContainerSafeaAreaInsets = calculateContainerSafeAreaInsets(for: message, at: indexPath)
    }

    open override func sizeForItem(at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        let message = dataSource.messageForItem(at: indexPath, in: messagesLayout.messagesCollectionView)
        let itemHeight = cellContentHeight(for: message, at: indexPath)
        return CGSize(width: messagesLayout.itemWidth, height: itemHeight)
    }

    open func cellContentHeight(for message: MessageType, at indexPath: IndexPath) -> CGFloat {

        let messageContainerHeight = messageContainerSize(for: message, at: indexPath).height
        let cellBottomLabelHeight = cellBottomLabelSize(for: message, at: indexPath).height
        let messageBottomLabelHeight = messageBottomLabelSize(for: message, at: indexPath).height
        let cellTopLabelHeight = cellTopLabelSize(for: message, at: indexPath).height
        let messageTopLabelHeight = messageTopLabelSize(for: message, at: indexPath).height
        let messageVerticalPadding = messageContainerPadding(for: message).vertical
        let avatarHeight = avatarSize(for: message).height
        let avatarVerticalPosition = avatarPosition(for: message).vertical
        let accessoryViewHeight = accessoryViewSize(for: message).height

        switch avatarVerticalPosition {
        case .messageCenter:
            let totalLabelHeight: CGFloat = cellTopLabelHeight + messageTopLabelHeight
                + messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight
            let cellHeight = max(avatarHeight, totalLabelHeight)
            return max(cellHeight, accessoryViewHeight)
        case .messageBottom:
            var cellHeight: CGFloat = 0
            cellHeight += messageBottomLabelHeight
            cellHeight += cellBottomLabelHeight
            let labelsHeight = messageContainerHeight + messageVerticalPadding + cellTopLabelHeight + messageTopLabelHeight
            cellHeight += max(labelsHeight, avatarHeight)
            return max(cellHeight, accessoryViewHeight)
        case .messageTop:
            var cellHeight: CGFloat = 0
            cellHeight += cellTopLabelHeight
            cellHeight += messageTopLabelHeight
            let labelsHeight = messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight
            cellHeight += max(labelsHeight, avatarHeight)
            return max(cellHeight, accessoryViewHeight)
        case .messageLabelTop:
            var cellHeight: CGFloat = 0
            cellHeight += cellTopLabelHeight
            let messageLabelsHeight = messageContainerHeight + messageBottomLabelHeight + messageVerticalPadding + messageTopLabelHeight + cellBottomLabelHeight
            cellHeight += max(messageLabelsHeight, avatarHeight)
            return max(cellHeight, accessoryViewHeight)
        case .cellTop, .cellBottom:
            let totalLabelHeight: CGFloat = cellTopLabelHeight + messageTopLabelHeight
                + messageContainerHeight + messageVerticalPadding + messageBottomLabelHeight + cellBottomLabelHeight
            let cellHeight = max(avatarHeight, totalLabelHeight)
            return max(cellHeight, accessoryViewHeight)
        }
    }
    
    open func messageContainerMinSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        
        if messageTopLabelPosition(for: message).isInner || messageBottomLabelPosition(for: message).isInner {
            let maxWidth = messageContainerMaxWidth(for: message);
            var minWidth: CGFloat? = nil;
            //var minHeight: CGFloat = 0;
            
            if let tpLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath) {
                let alignemt = netMessageTopLabelAlignment(for: message)
                let tpLblSize = labelSize(for: tpLblTxt, considering: maxWidth).inset(by: alignemt.textInsets)
                minWidth = minWidth != nil ? max(minWidth!, tpLblSize.width) : tpLblSize.width
                
                //let height = messageTopLabelSize(for: message, at: indexPath).height
                //minHeight = height >= 0 ? height : tpLblSize.height
            }
            
            if let btmLblTxt = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath) {
                let alignemt = netMessageBottomLabelAlignment(for: message)
                let btmLblSize = labelSize(for: btmLblTxt, considering: maxWidth).inset(by: alignemt.textInsets)
                minWidth = minWidth != nil ? max(minWidth!, btmLblSize.width) : btmLblSize.width
                
                //let height = messageBottomLabelSize(for: message, at: indexPath).height
                //minHeight += height >= 0 ? height : btmLblSize.height
            }
            
            let containerInsets = messageContainerInsets(for: message)
            return CGSize(width: minWidth ?? 0, height: 0).inset(by: containerInsets)
        }
        
        let containerInsets = messageContainerInsets(for: message)
        return CGSize(width: containerInsets.horizontal, height: containerInsets.vertical)
    }

    // MARK: - Avatar

    open func avatarPosition(for message: MessageType) -> AvatarPosition {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        var position = isFromCurrentSender ? outgoingAvatarPosition : incomingAvatarPosition

        switch position.horizontal {
        case .cellTrailing, .cellLeading:
            break
        case .natural:
            position.horizontal = isFromCurrentSender ? .cellTrailing : .cellLeading
        }
        return position
    }

    open func avatarSize(for message: MessageType) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingAvatarSize : incomingAvatarSize
    }

    // MARK: - Top cell Label

    open func cellTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.cellTopLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }

    open func cellTopLabelAlignment(for message: MessageType) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingCellTopLabelAlignment : incomingCellTopLabelAlignment
    }
    
    // MARK: - Top message Label
    
    open func messageTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.messageTopLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }
    
    open func messageTopLabelAlignment(for message: MessageType, attributes: MessagesCollectionViewLayoutAttributes) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        
        switch messageTopLabelPosition(for: message) {
        case .inner, .inline:
            let alignment = isFromCurrentSender ? outgoingMessageTopLabelAlignment : incomingMessageTopLabelAlignment
            
            var messagePadding = messageContainerPadding(for: message)
            if isFromCurrentSender {messagePadding = messagePadding.flipHorizontally() }
            
            let leftInset = avatarSize(for: message).width + avatarLeadingTrailingPadding + messagePadding.left
            let rightInset = messagesLayout.itemWidth - leftInset - attributes.messageContainerSize.width
            
            return .init(
                textAlignment: alignment.textAlignment,
                textInsets: .init(
                    top: alignment.textInsets.top,
                    bottom: alignment.textInsets.bottom,
                    left: alignment.textInsets.left + (isFromCurrentSender ? rightInset : leftInset),
                    right: alignment.textInsets.right + (isFromCurrentSender ? leftInset : rightInset))
            )
        default:
            return isFromCurrentSender ? outgoingMessageTopLabelAlignment : incomingMessageTopLabelAlignment
        }
    }
    
    open func netMessageTopLabelAlignment(for message: MessageType) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingMessageTopLabelAlignment : incomingMessageTopLabelAlignment
    }
    
    open func netMessageTopLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        if let tpLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath) {
            let maxWidth = messageContainerMaxWidth(for: message);
            let alignemt = netMessageTopLabelAlignment(for: message)
            return labelSize(for: tpLblTxt, considering: maxWidth).inset(by: alignemt.textInsets)
        } else {
            return messageTopLabelSize(for: message, at: indexPath);
        }
    }
    
    open func messageTopLabelPosition(for message: MessageType) -> MessageLabelPosition {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        let pos = isFromCurrentSender ? outgoingMessageTopLabelPosition : incomingMessageTopLabelPosition
        return pos == .inline && !canUseInlineMessageTopLabel(for: message) ? .inner : pos
    }
    
    /// Returns whether message cell accepts inline messageBottomLabel.
    open func canUseInlineMessageTopLabel(for message: MessageType) -> Bool {
        return false
    }
    
    open func messageTopLabelSafeArea(position: MessageLabelPosition, message: MessageType, at indexPath: IndexPath) -> CGFloat {
        guard position.isInner else { return 0; }
        
        let dataSource = messagesLayout.messagesDataSource;
        let labelSize = self.messageTopLabelSize(for: message, at: indexPath);
        
        if position == .inline, let topLblTxt = dataSource.messageTopLabelAttributedText(for: message, at: indexPath){
            let maxWidth = self.messageContainerMaxWidth(for: message);
            
            // Calculate horizontal spacing needed to avoid overlapping with
            // message's top label. (Only last-line should be inline).
            let textAlignment = netMessageTopLabelAlignment(for: message);
            let frame = topLblTxt.lastLineFrame(labelWidth: maxWidth - textAlignment.textInsets.horizontal);
            
            return max(labelSize.height - frame.height, 0);
        }
        
        return labelSize.height;
    }

    // MARK: - Message time label

    open func messageTimeLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        guard let attributedText = dataSource.messageTimestampLabelAttributedText(for: message, at: indexPath) else {
            return .zero
        }
        let size = attributedText.size()
        return CGSize(width: size.width, height: size.height)
    }

    // MARK: - Bottom cell Label
    
    open func cellBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.cellBottomLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }
    
    open func cellBottomLabelAlignment(for message: MessageType) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingCellBottomLabelAlignment : incomingCellBottomLabelAlignment
    }

    // MARK: - Bottom Message Label

    open func messageBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let layoutDelegate = messagesLayout.messagesLayoutDelegate
        let collectionView = messagesLayout.messagesCollectionView
        let height = layoutDelegate.messageBottomLabelHeight(for: message, at: indexPath, in: collectionView)
        return CGSize(width: messagesLayout.itemWidth, height: height)
    }

    open func messageBottomLabelAlignment(for message: MessageType, attributes: MessagesCollectionViewLayoutAttributes) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        
        switch messageBottomLabelPosition(for: message) {
        case .inner, .inline:
            let alignment = isFromCurrentSender ? outgoingMessageBottomLabelAlignment : incomingMessageBottomLabelAlignment
            
            var messagePadding = messageContainerPadding(for: message)
            if isFromCurrentSender { messagePadding = messagePadding.flipHorizontally() }
            
            let leftInset = avatarSize(for: message).width + avatarLeadingTrailingPadding + messagePadding.left
            let rightInset = messagesLayout.itemWidth - leftInset - attributes.messageContainerSize.width
            
            return .init(
                textAlignment: alignment.textAlignment,
                textInsets: .init(
                    top: alignment.textInsets.top,
                    bottom: alignment.textInsets.bottom,
                    left: alignment.textInsets.left + (isFromCurrentSender ? rightInset : leftInset),
                    right: alignment.textInsets.right + (isFromCurrentSender ? leftInset : rightInset))
            )
        default:
            return isFromCurrentSender ? outgoingMessageBottomLabelAlignment : incomingMessageBottomLabelAlignment
        }
    }
    
    open func netMessageBottomLabelAlignment(for message: MessageType) -> LabelAlignment {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingMessageBottomLabelAlignment : incomingMessageBottomLabelAlignment
    }
    
    open func netMessageBottomLabelSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        if let btmLblTxt = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath) {
            let maxWidth = messageContainerMaxWidth(for: message);
            let alignemt = netMessageBottomLabelAlignment(for: message)
            return labelSize(for: btmLblTxt, considering: maxWidth).inset(by: alignemt.textInsets)
        } else {
            return messageBottomLabelSize(for: message, at: indexPath);
        }
    }
    
    open func messageBottomLabelPosition(for message: MessageType) -> MessageLabelPosition {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        let pos = isFromCurrentSender ? outgoingMessageBottomLabelPosition : incomingMessageBottomLabelPosition
        return pos == .inline && !canUseInlineMessageBottomLabel(for: message) ? .inner : pos
    }
    
    /// Returns whether message cell accepts inline messageBottomLabel.
    open func canUseInlineMessageBottomLabel(for message: MessageType) -> Bool {
        return false
    }
    
    open func messageBottomLabelSafeArea(position: MessageLabelPosition, message: MessageType, at indexPath: IndexPath) -> CGFloat {
        guard position.isInner else { return 0; }
        
        let dataSource = messagesLayout.messagesDataSource;
        let labelSize = self.messageBottomLabelSize(for: message, at: indexPath);
        
        if position == .inline, let btmLblTxt = dataSource.messageBottomLabelAttributedText(for: message, at: indexPath){
            let maxWidth = self.messageContainerMaxWidth(for: message);
            
            // Calculate horizontal spacing needed to avoid overlapping with
            // message's top label.
            let textAlignment = netMessageBottomLabelAlignment(for: message);
            let frame = btmLblTxt.firstLineFrame(labelWidth: maxWidth - textAlignment.textInsets.horizontal);
            
            return max(labelSize.height - frame.height, 0);
        }
        
        return labelSize.height;
    }

    // MARK: - Accessory View

    public func accessoryViewSize(for message: MessageType) -> CGSize {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingAccessoryViewSize : incomingAccessoryViewSize
    }

    public func accessoryViewPadding(for message: MessageType) -> HorizontalEdgeInsets {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingAccessoryViewPadding : incomingAccessoryViewPadding
    }
    
    public func accessoryViewPosition(for message: MessageType) -> AccessoryPosition {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingAccessoryViewPosition : incomingAccessoryViewPosition
    }

    // MARK: - MessageContainer

    open func messageContainerPadding(for message: MessageType) -> UIEdgeInsets {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingMessagePadding : incomingMessagePadding
    }
    
    open func messageContainerInsets(for message: MessageType) -> UIEdgeInsets {
        let dataSource = messagesLayout.messagesDataSource
        let isFromCurrentSender = dataSource.isFromCurrentSender(message: message)
        return isFromCurrentSender ? outgoingMessageContainerInsets : incomingMessageContainerInsets
    }

    open func messageContainerSize(for message: MessageType, at indexPath: IndexPath) -> CGSize {
        // Returns .zero by default
        return messageContainerMinSize(for: message, at: indexPath)
    }

    open func messageContainerMaxWidth(for message: MessageType) -> CGFloat {
        return grossMessageContainerMaxWidth(for: message)
    }
    
    open func grossMessageContainerMaxWidth(for message: MessageType) -> CGFloat {
        let avatarWidth = avatarSize(for: message).width
        let messagePadding = messageContainerPadding(for: message)
        let accessoryWidth = accessoryViewSize(for: message).width
        let accessoryPadding = accessoryViewPadding(for: message)
        return messagesLayout.itemWidth - avatarWidth - messagePadding.horizontal - accessoryWidth - accessoryPadding.horizontal - avatarLeadingTrailingPadding
    }
    
    open func calculateContainerSafeAreaInsets(for message: MessageType, at indexPath: IndexPath) -> UIEdgeInsets {
        let containerInsets = messageContainerInsets(for: message);
        var insets: UIEdgeInsets = .zero;
        
        let tpLblPosition = messageTopLabelPosition(for: message);
        insets.top = messageTopLabelSafeArea(position: tpLblPosition, message: message, at: indexPath) + containerInsets.top;
        
        let btmLblPosition = messageBottomLabelPosition(for: message);
        insets.bottom = messageBottomLabelSafeArea(position: btmLblPosition, message: message, at: indexPath) + containerInsets.bottom;
        
        return insets;
    }

    // MARK: - Helpers

    public var messagesLayout: MessagesCollectionViewFlowLayout {
        guard let layout = layout as? MessagesCollectionViewFlowLayout else {
            fatalError("Layout object is missing or is not a MessagesCollectionViewFlowLayout")
        }
        return layout
    }

    internal func labelSize(for attributedText: NSAttributedString, considering maxWidth: CGFloat) -> CGSize {
        let constraintBox = CGSize(width: maxWidth, height: .greatestFiniteMagnitude)
        let rect = attributedText.boundingRect(with: constraintBox, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil).integral

        return rect.size
    }
}

fileprivate extension UIEdgeInsets {
    init(top: CGFloat = 0, bottom: CGFloat = 0, left: CGFloat = 0, right: CGFloat = 0) {
        self.init(top: top, left: left, bottom: bottom, right: right)
    }
}

internal extension CGSize {
    
    func inset(by insets: UIEdgeInsets, multiplier: CGFloat = 1) -> CGSize {
        return CGSize(width: self.width + (insets.horizontal*multiplier),
                      height: self.height + (insets.vertical*multiplier))
    }
}


extension String {
    
    fileprivate static var rtlSciriptRanges = [
        ["0590","05FF"], // Hebrew
        ["0600","06FF"], // Arabic
        ["07C0","07FF"], // NKo
        ["0700","074F"], // Syriac
        ["0780","07BF"], // Thaana
        ["2D30","2D7F"] // Tifinagh
    ]
    
    fileprivate static var nonDirectionalCharacters = "[\\s\n\0\\f\t\\v\'\"\\-0-9\\+\\?\\!\\W]"
    

    /// Tells whether the string is of a right to left script or not.
    var isRTL: Bool {
        //let txt = self.removingRegexMatches(pattern: String.nonDirectionalCharacters);
        for char in self {
            if char.isSpecialCharacter {
                continue;
            }
            for range in String.rtlSciriptRanges {
                if char.isWithinUnicodeRange(from: UInt32(Int(range[0], radix: 16)!), to: UInt32(Int(range[1], radix: 16)!)) {
                    return true;
                }
            }
            return false
        }
        return false;
    }
    
    func removingRegexMatches(pattern: String, replaceWith: String = "") -> String {
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
            let range = NSRange(location: 0, length: count)
            return regex.stringByReplacingMatches(in: self, options: [], range: range, withTemplate: replaceWith)
        } catch {
            return self
        }
    }
    
}

extension Character {
    
    func isWithinUnicodeRange(from: UInt32, to: UInt32) -> Bool {
        guard let uni = self.unicodeScalars.first?.value else { return false; }
        return from <= uni && uni <= to;
    }
    
    var isSpecialCharacter: Bool {
        // Check if the receiver is a spacial character: ~`!@#$%^&*()-_+={}[]\\/:;\"'<>,.?1234567890 \r\n\t
        guard let u = unicodeScalars.first?.value else { return false; }
        return u == 9 || u == 13 || (u >= 32 && u <= 64) || (u >= 91 && u <= 96) || (u >= 123 && u <= 126)
    }
}
