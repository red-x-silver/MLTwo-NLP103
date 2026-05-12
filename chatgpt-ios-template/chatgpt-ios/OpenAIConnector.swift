//
//  OpenAIConnector.swift
//  chatgpt-ios template app
//
//  Created by XYI on 24/05/2023.
//  Code is referenced from https://medium.com/codex/how-to-use-chatgpt-with-swift-f4ee213d6ba9


import Foundation
import Combine

// Minimal models for decoding OpenAI chat responses
private struct ChatCompletionResponse: Decodable {
    struct Choice: Decodable {
        struct Message: Decodable {
            let role: String
            let content: String?
        }
        let index: Int?
        let message: Message
    }
    let id: String?
    let choices: [Choice]
}

private struct OpenAIErrorResponse: Decodable {
    struct APIError: Decodable { let message: String }
    let error: APIError
}

//

class OpenAIConnector: ObservableObject {
    /// This URL might change in the future, so if you get an error, make sure to check the OpenAI API Reference.
    let openAIURL = URL(string: "https://api.openai.com/v1/chat/completions")

    let openAIKey = ""
    
    /// This is what stores your messages. You can see how to use it in a SwiftUI view here:
    @Published var messageLog: [[String: String]] = [
        /// Modify this to change the personality of the assistant.
        ["role": "system", "content": "You're a friendly, helpful assistant"]
    ]

    func sendToAssistant() {
        /// DON'T TOUCH THIS
        var request = URLRequest(url: self.openAIURL!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(self.openAIKey)", forHTTPHeaderField: "Authorization")
        
        let httpBody: [String: Any] = [
            "model" : "gpt-4o-mini",
            "messages" : messageLog,
            "temperature": 0.7
        ]
        
        /// DON'T TOUCH THIS
        var httpBodyJson: Data? = nil

        do {
//            httpBodyJson = try JSONEncoder().encode(httpBody)
            httpBodyJson = try JSONSerialization.data(withJSONObject: httpBody, options: .prettyPrinted)
        } catch {
            print("Unable to convert to JSON \(error)")
            logMessage("error", messageUserType: .assistant)
        }
        
        request.httpBody = httpBodyJson
        
        if let requestData = executeRequest(request: request, withSessionConfig: nil) {
            let jsonStr = String(data: requestData, encoding: String.Encoding(rawValue: String.Encoding.utf8.rawValue))!
            print(jsonStr)
            // Try to decode a successful chat completion
            if let data = jsonStr.data(using: .utf8) {
                if let completion = try? JSONDecoder().decode(ChatCompletionResponse.self, from: data),
                   let first = completion.choices.first {
                    if let content = first.message.content, !content.isEmpty {
                        logMessage(content, messageUserType: .assistant)
                    } else {
                        logMessage("No content returned from assistant.", messageUserType: .assistant)
                        print("Warning: message content missing in first choice: \(completion)")
                    }
                } else if let apiError = try? JSONDecoder().decode(OpenAIErrorResponse.self, from: data) {
                    logMessage("API error: \(apiError.error.message)", messageUserType: .assistant)
                } else {
                    // Log a short preview of the raw payload to help debugging
                    let preview = jsonStr.count > 500 ? String(jsonStr.prefix(500)) + "…" : jsonStr
                    print("Unhandled response payload preview: \n\(preview)")
                    logMessage("Failed to decode response.", messageUserType: .assistant)
                }
            } else {
                logMessage("Failed to decode response.", messageUserType: .assistant)
            }
        }

        
    }
}


/// Don't worry about this too much. This just gets rid of errors when using messageLog in a SwiftUI List or ForEach.
extension Dictionary: Identifiable { public var id: UUID { UUID() } }
extension Array: Identifiable { public var id: UUID { UUID() } }
extension String: Identifiable { public var id: UUID { UUID() } }

/// DO NOT TOUCH THIS. LEAVE IT ALONE.
extension OpenAIConnector {
    private func executeRequest(request: URLRequest, withSessionConfig sessionConfig: URLSessionConfiguration?) -> Data? {
        let semaphore = DispatchSemaphore(value: 0)
        let session: URLSession
        if (sessionConfig != nil) {
            session = URLSession(configuration: sessionConfig!)
        } else {
            session = URLSession.shared
        }
        var requestData: Data?
        let task = session.dataTask(with: request as URLRequest, completionHandler:{ (data: Data?, response: URLResponse?, error: Error?) -> Void in
            if error != nil {
                print("error: \(error!.localizedDescription): \(error!.localizedDescription)")
            } else if data != nil {
                requestData = data
            }
            
            print("Semaphore signalled")
            semaphore.signal()
        })
        task.resume()
        
        // Handle async with semaphores. Max wait of 50 seconds
        let timeout = DispatchTime.now() + .seconds(50)
        print("Waiting for semaphore signal")
        let retVal = semaphore.wait(timeout: timeout)
        print("Done waiting, obtained - \(retVal)")
        return requestData
    }
}

extension OpenAIConnector {
    /// This function makes it simpler to append items to messageLog.
    func logMessage(_ message: String, messageUserType: MessageUserType) {
        var messageUserTypeString = ""
        switch messageUserType {
        case .user:
            messageUserTypeString = "user"
        case .assistant:
            messageUserTypeString = "assistant"
        }
        
        messageLog.append(["role": messageUserTypeString, "content": message])
    }
    
    enum MessageUserType {
        case user
        case assistant
    }
}

