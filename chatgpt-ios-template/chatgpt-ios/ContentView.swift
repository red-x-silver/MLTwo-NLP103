//
//  ContentView.swift
//  ChatGPTDemo
//
//  Created by NMS15065-7-adisara on 3/3/23.
//   Code is referenced from https://medium.com/codex/how-to-use-chatgpt-with-swift-f4ee213d6ba9

import SwiftUI

struct ContentView: View {
    @State var textField = ""
    @StateObject var connector = OpenAIConnector()
    //@EnvironmentObject var connector: OpenAIConnector
    
    var body: some View {
        VStack {
            ScrollView {
                ForEach(connector.messageLog) { message in
                    MessageView(message: message)
                }
            }
            
            Divider()
            
            HStack {
                TextField("Type here", text: $textField)
                Button("Send") {
                    connector.logMessage(textField, messageUserType: .user)
                    connector.sendToAssistant()
                    print("messageLog")
                }
            }
            
        }.environmentObject(connector)
            .padding()
            
           
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        
        ContentView().environmentObject(OpenAIConnector())
    }
}

struct MessageView: View {
    var message: [String: String]
    
    var messageColor: Color {
        if message["role"] == "user" {
            return .gray
        } else if message["role"] == "assistant" {
            return .green
        } else {
            return .red
        }
    }
    
    var body: some View {
        if message["role"] != "system" {
            HStack {
                if message["role"] == "user" {
                    Spacer()
                }
                
                
                Text(message["content"] ?? "error")
                    .foregroundColor(.white)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 25).foregroundColor(messageColor))
                    .shadow(radius: 25).cornerRadius(25)
                
                if message["role"] == "assistant" {
                    Spacer()
                }
            }
        }
    }
}
