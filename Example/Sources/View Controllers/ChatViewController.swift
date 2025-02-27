/*
MIT License

Copyright (c) 2017-2020 MessageKit

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
import MessageKit
import InputBarAccessoryView

/// A base class for the example controllers
class ChatViewController: MessagesViewController, MessagesDataSource {

    // MARK: - Public properties

    /// The `BasicAudioController` control the AVAudioPlayer state (play, pause, stop) and update audio cell UI accordingly.
    lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)

    lazy var messageList: [MockMessage] = []
    
    private(set) lazy var refreshControl: UIRefreshControl = {
        let control = UIRefreshControl()
        control.addTarget(self, action: #selector(loadMoreMessages), for: .valueChanged)
        return control
    }()

    // MARK: - Private properties

    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        
        configureMessageCollectionView()
        configureMessageInputBar()
        loadFirstMessages()
        title = "MessageKit"
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        MockSocket.shared.connect(with: [SampleData.shared.nathan, SampleData.shared.wu])
            .onNewMessage { [weak self] message in
                self?.insertMessage(message)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        MockSocket.shared.disconnect()
        audioController.stopAnyOngoingPlaying()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    func loadFirstMessages() {
        DispatchQueue.global(qos: .userInitiated).async {
            let count = UserDefaults.standard.mockMessagesCount()
            SampleData.shared.getMessages(count: count) { messages in
                DispatchQueue.main.async {
                    self.messageList = messages
                    self.messagesCollectionView.reloadData()
                    self.messagesCollectionView.scrollToLastItem()
                }
            }
        }
    }
    
    @objc func loadMoreMessages() {
        DispatchQueue.global(qos: .userInitiated).asyncAfter(deadline: .now() + 1) {
            SampleData.shared.getMessages(count: 20) { messages in
                DispatchQueue.main.async {
                    self.messageList.insert(contentsOf: messages, at: 0)
                    self.messagesCollectionView.reloadDataAndKeepOffset()
                    self.refreshControl.endRefreshing()
                }
            }
        }
    }
    
    func configureMessageCollectionView() {
        
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        
        scrollsToLastItemOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false 

        showMessageTimestampOnSwipeLeft = true // default false
        
        messagesCollectionView.refreshControl = refreshControl
        
        let layout = messagesCollectionView.messagesCollectionViewFlowLayout
        
        layout.setMessageIncomingTopLabelPosition(.inner);
        layout.setMessageIncomingMessageTopLabelAlignment(.init(textAlignment: .left, textInsets: .init(top: 0, left: 18, bottom: 0, right: 14)))
        
        layout.setMessageIncomingBottomLabelPosition(.inline);
        layout.setMessageIncomingMessageBottomLabelAlignment(.init(textAlignment: .right, textInsets: .init(top: 0, left: 18, bottom: 0, right: 14)))
        
        layout.setMessageOutgoingTopLabelPosition(.inner);
        layout.setMessageOutgoingMessageTopLabelAlignment(.init(textAlignment: .right, textInsets: .init(top: 0, left: 14, bottom: 0, right: 18)))
        
        layout.setMessageOutgoingBottomLabelPosition(.inline);
        layout.setMessageOutgoingMessageBottomLabelAlignment(.init(textAlignment: .left, textInsets: .init(top: 0, left: 14, bottom: 0, right: 18)))
        
        layout.messageSizeCalculators().forEach {
            
            if let textSizeCalculator = $0 as? TextMessageSizeCalculator {
                textSizeCalculator.incomingMessageLabelInsets = UIEdgeInsets(top: 0, left: 18, bottom: 0, right: 14)
                textSizeCalculator.outgoingMessageLabelInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 18)
                
                $0.incomingMessageContainerInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
                $0.outgoingMessageContainerInsets = UIEdgeInsets(top: 4, left: 0, bottom: 4, right: 0)
            } else {
                $0.incomingMessageContainerInsets = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 4)
                $0.outgoingMessageContainerInsets = UIEdgeInsets(top: 4, left: 4, bottom: 4, right: 8)
            }
        }
        
        layout.linkPreviewMessageSizeCalculator.incomingMessageBottomLabelPosition = .inner;
        
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = .primaryColor
        messageInputBar.sendButton.setTitleColor(.primaryColor, for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.primaryColor.withAlphaComponent(0.3),
            for: .highlighted
        )
    }
    
    // MARK: - Helpers
    
    func insertMessage(_ message: MockMessage) {
        messageList.append(message)
        // Reload last section to update header/footer labels and insert a new one
        messagesCollectionView.performBatchUpdates({
            messagesCollectionView.insertSections([messageList.count - 1])
            if messageList.count >= 2 {
                messagesCollectionView.reloadSections([messageList.count - 2])
            }
        }, completion: { [weak self] _ in
            if self?.isLastSectionVisible() == true {
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        })
    }
    
    func isLastSectionVisible() -> Bool {
        
        guard !messageList.isEmpty else { return false }
        
        let lastIndexPath = IndexPath(item: 0, section: messageList.count - 1)
        
        return messagesCollectionView.indexPathsForVisibleItems.contains(lastIndexPath)
    }

    // MARK: - MessagesDataSource

    func currentSender() -> SenderType {
        return SampleData.shared.currentSender
    }

    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messageList.count
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }

    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if indexPath.section % 3 == 0 {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }

    func cellBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: "Read", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }

    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: message.sender.displayName, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .caption1)
        ])
        
        /*guard let sizeCalc = messagesCollectionView.messagesCollectionViewFlowLayout.cellSizeCalculatorForItem(at: indexPath) as? MessageSizeCalculator else {
            return nil;
        }
        
        let name = message.sender.displayName
        if sizeCalc.messageTopLabelPosition(for: message) == .inline {
            var font: UIFont? = nil;
            if let sizeCalc = sizeCalc as? TextMessageSizeCalculator {
                font = sizeCalc.messageLabelFont.bolder ?? sizeCalc.messageLabelFont;
            } else {
                font = UIFont.systemFont(ofSize: UIFont.labelFontSize, weight: .medium)
            }
            
            return NSAttributedString(string: name, attributes: [
                .font: font ?? UIFont.preferredFont(forTextStyle: .caption1)
            ])
        } else {
            return NSAttributedString(string: name, attributes: [
                .font: UIFont.preferredFont(forTextStyle: .caption1)
            ])
        }*/
    }

    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let dateString = formatter.string(from: message.sentDate)
        return NSAttributedString(string: dateString, attributes: [
            .font: UIFont.preferredFont(forTextStyle: .caption2)
        ])
    }
    
    func textCell(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UICollectionViewCell? {
        return nil
    }
    
    
}

// MARK: - MessageCellDelegate

extension ChatViewController: MessageCellDelegate {
    func didTapAvatar(in cell: MessageCollectionViewCell) {
        print("Avatar tapped")
    }
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        print("Message tapped")
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        print("Image tapped")
    }
    
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func didTapCellBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom cell label tapped")
    }
    
    func didTapMessageTopLabel(in cell: MessageCollectionViewCell) {
        print("Top message label tapped")
    }
    
    func didTapMessageBottomLabel(in cell: MessageCollectionViewCell) {
        print("Bottom label tapped")
    }

    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
            let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
                print("Failed to identify message when audio cell receive tap gesture")
                return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }

    func didStartAudio(in cell: AudioMessageCell) {
        print("Did start playing audio sound")
    }

    func didPauseAudio(in cell: AudioMessageCell) {
        print("Did pause audio sound")
    }

    func didStopAudio(in cell: AudioMessageCell) {
        print("Did stop audio sound")
    }

    func didTapAccessoryView(in cell: MessageCollectionViewCell) {
        print("Accessory view tapped")
    }

}

// MARK: - MessageLabelDelegate

extension ChatViewController: MessageLabelDelegate {
    func didSelectAddress(_ addressComponents: [String: String]) {
        print("Address Selected: \(addressComponents)")
    }
    
    func didSelectDate(_ date: Date) {
        print("Date Selected: \(date)")
    }
    
    func didSelectPhoneNumber(_ phoneNumber: String) {
        print("Phone Number Selected: \(phoneNumber)")
    }
    
    func didSelectURL(_ url: URL) {
        print("URL Selected: \(url)")
    }
    
    func didSelectTransitInformation(_ transitInformation: [String: String]) {
        print("TransitInformation Selected: \(transitInformation)")
    }

    func didSelectHashtag(_ hashtag: String) {
        print("Hashtag selected: \(hashtag)")
    }

    func didSelectMention(_ mention: String) {
        print("Mention selected: \(mention)")
    }

    func didSelectCustom(_ pattern: String, match: String?) {
        print("Custom data detector patter selected: \(pattern)")
    }
}

// MARK: - MessageInputBarDelegate

extension ChatViewController: InputBarAccessoryViewDelegate {

    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }

    func processInputBar(_ inputBar: InputBarAccessoryView) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in

            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }

        let components = inputBar.inputTextView.components
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
        inputBar.inputTextView.resignFirstResponder()
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                inputBar.sendButton.stopAnimating()
                inputBar.inputTextView.placeholder = "Aa"
                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToLastItem(animated: true)
            }
        }
    }

    private func insertMessages(_ data: [Any]) {
        for component in data {
            let user = SampleData.shared.currentSender
            if let str = component as? String {
                let message = MockMessage(text: str, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            } else if let img = component as? UIImage {
                let message = MockMessage(image: img, user: user, messageId: UUID().uuidString, date: Date())
                insertMessage(message)
            }
        }
    }
}



extension UIFont.Weight {
    static var allCases: [UIFont.Weight] {
        return [.ultraLight, .thin, .light, .regular, .medium, .semibold, .bold, .heavy, .black];
    }
    
    var stringValue: String {
        switch self {
        case .ultraLight: return "ultraLight";
        case .thin: return "thin";
        case .light: return "light";
        case .regular: return "regular";
        case .medium: return "medium";
        case .semibold: return "semiBold";
        case .bold: return "bold";
        case .heavy: return "heavy";
        case .black: return "black";
        default: return "undefined";
        }
    }
    
    func matches(weightOfFontWithName name: String) -> Bool {
        let name = name.lowercased();
        if self == .ultraLight && name.contains("ultra") && name.contains("light") {
            return true;
        } else if self == .semibold && name.contains("semi") && name.contains("bold") {
            return true;
        } else if name.contains(stringValue.lowercased()) {
            return true;
        }
        
        return false;
    }
    
    static func weight(forFontWithName name: String) -> UIFont.Weight? {
        let weights = self.allCases;
        for weight in weights {
            if weight.matches(weightOfFontWithName: name){
                return weight;
            }
        }
        
        return nil;
    }
}
extension UIFont {
    
    func font(ofWeight weight: UIFont.Weight) -> UIFont? {
        let fontNames = UIFont.fontNames(forFamilyName: familyName);
        var selected: [String] = [];
        for name in fontNames {
            if weight.matches(weightOfFontWithName: name){
                selected.append(name);
            }
        }
        
        if selected.isEmpty && fontNames.count == 1 {
            selected = fontNames;
        } else if weight == .regular && selected.isEmpty {
            var weights = UIFont.Weight.allCases;
            weights.removeAll { $0 == .regular }
            
            for name in fontNames {
                if weights.compactMap({ $0.matches(weightOfFontWithName: name) ? true : nil }).isEmpty {
                    selected.append(name);
                    break;
                }
            }
        }
        
        let isItalic = fontName.lowercased().contains("italic");
        for name in selected {
            if name.lowercased().contains("italic") == isItalic {
                return UIFont(name: name, size: self.pointSize);
            }
        }
        
        if selected.count >= 1 {
            return UIFont(name: selected.first!, size: self.pointSize);
        }
        return nil;
    }
    
    var bolder: UIFont? {
        guard let weight = UIFont.Weight.weight(forFontWithName: self.fontName) else {
            return nil;
        }
        
        return font(bolderThan: weight);
    }
    
    var lighter: UIFont? {
        guard let weight = UIFont.Weight.weight(forFontWithName: self.fontName) else {
            return nil;
        }
        
        return font(lighterThan: weight);
    }
    
    func font(bolderThan weight: UIFont.Weight) -> UIFont? {
        let weights = UIFont.Weight.allCases;
        guard let i = weights.firstIndex(of: weight) else { return nil; }
        
        for indx in (i + 1) ..< weights.count {
            if let font = self.font(ofWeight: weights[indx]){
                return font;
            }
        }
        
        return nil;
    }
    
    func font(lighterThan weight: UIFont.Weight) -> UIFont? {
        let weights = UIFont.Weight.allCases;
        guard let i = weights.firstIndex(of: weight) else { return nil; }
        
        for indx in 0 ..< i {
            let _indx = i - indx - 1
            if let font = self.font(ofWeight: weights[_indx]){
                return font;
            }
        }
        
        return nil;
    }
    
//    func font(ofWeight weight: UIFont.Weight) -> UIFont? {
//        let familyName = familyName.lowercased();
//        let fontName = fontName.lowercased()
//        var weight: UIFont.Weight = .regular;
//
//        let weights = UIFont.Weight.allCases;
//        for weight in weights {
//            if fontName.contains(<#T##element: Character##Character#>)
//        }
//    }
}
