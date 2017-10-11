/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

import UIKit
import SimpleLogger
import Starscream

final class ViewController: UIViewController {
    
    // MARK: - Properties
    var username: String = ""
    var socket: WebSocket = WebSocket(url: URL(string: ViewController.Constants.ServerUrlString.base)!, protocols: [ViewController.Constants.WebSocketProtocol.chat])
    
    // MARK: - IBOutlets
    @IBOutlet var emojiLabel: UILabel!
    @IBOutlet var usernameLabel: UILabel!
    
    // MARK: - Initializaiton
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        self.socket.disconnect(forceTimeout: 0)
        self.socket.delegate = nil
        
        Logger.debug.message("\(String(describing: ViewController.self)) deinitialized!")
    }
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // configurations
        self.navigationItem.hidesBackButton = true
        
        self.configure(self.socket)
    }
}

// MARK: - Configurations
fileprivate extension ViewController {
    
    fileprivate func configure(_ webSocket: WebSocket) {
        webSocket.delegate = self
        webSocket.connect()
    }
}

// MARK: - IBActions
extension ViewController {
    
    @IBAction func selectedEmojiUnwind(unwindSegue: UIStoryboardSegue) {
        guard
            let viewController = unwindSegue.source as? CollectionViewController,
            let emoji = viewController.selectedEmoji()
        else {
                return
        }
        
        self.sendMessage(emoji)
    }
}

// MARK: - WebSocketDelegate
extension ViewController: WebSocketDelegate {
    
    func websocketDidConnect(socket: WebSocketClient) {
        Logger.network.message("WebSocket connected!")
    }
    
    func websocketDidDisconnect(socket: WebSocketClient, error: Error?) {
        Logger.network.message("WebSocket disconected!")
        
        self.performSegue(withIdentifier: ViewController.Constants.SegueIdentifier.websocketDisconnected, sender: self)
    }
    
    func websocketDidReceiveMessage(socket: WebSocketClient, text: String) {
        // obtaining data and serializing it to json
        guard let valid_data: Data = text.data(using: .utf16) else {
            Logger.error.message("Unable to obtatin \(String(describing: Data.self)) object")
            return
        }
        guard let valid_jsonData: Any = try? JSONSerialization.jsonObject(with: valid_data, options: JSONSerialization.ReadingOptions.allowFragments) else {
            Logger.error.message("Unable to serialize jsonData!")
            return
        }
        guard let valid_jsonDict: [String: Any] = valid_jsonData as? [String: Any] else {
            Logger.error.message("Unable to construnc json dictionary!")
            return
        }
        guard let valid_messagaType: String = valid_jsonDict[ViewController.Constants.JsonKey.type.rawValue] as? String else {
            Logger.error.message("Unable to obtain message type")
            return
        }
        
        // message data
        guard valid_messagaType == ViewController.Constants.MessageType.message else {
            Logger.error.message("Invalid message type: \(valid_messagaType)! Expected: \(ViewController.Constants.MessageType.message)")
            return
        }
        guard let valid_messageData: [String: Any] = valid_jsonDict[ViewController.Constants.JsonKey.data.rawValue] as? [String: Any] else {
            Logger.error.message("Unable to obtain message data!")
            return
        }
        guard let valid_messageAuthor: String = valid_messageData[ViewController.Constants.JsonKey.author.rawValue] as? String else {
            Logger.error.message("Unable to obtain message author!")
            return
        }
        guard let valid_messageText: String = valid_messageData[ViewController.Constants.JsonKey.text.rawValue] as? String else {
            Logger.error.message("Unable to obtain message text!")
            return
        }
        
        // update ui
        self.messageReceived(valid_messageText, senderName: valid_messageAuthor)
    }
    
    func websocketDidReceiveData(socket: WebSocketClient, data: Data) {
        // TODO: implement
    }
}

// MARK: - FilePrivate
fileprivate extension ViewController {
    
    func sendMessage(_ message: String) {
        self.socket.write(string: message)
    }
    
    func messageReceived(_ message: String, senderName: String) {
        self.emojiLabel.text = message
        self.usernameLabel.text = senderName
    }
}

// MARK: - Constants
fileprivate extension ViewController {
    
    fileprivate struct Constants {
        
        fileprivate struct ServerUrlString {
            static let base: String = "ws://localhost:1337/"
        }
        
        fileprivate struct SegueIdentifier {
            static let websocketDisconnected: String = "websocketDisconnected"
        }
        
        fileprivate struct WebSocketProtocol {
            static let chat: String = "chat"
        }
        
        fileprivate enum JsonKey: String {
            case type
            case data
            case author
            case text
        }
        
        fileprivate struct MessageType {
            static let message: String = "message"
        }
    }
}
