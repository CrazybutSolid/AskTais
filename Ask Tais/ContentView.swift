//
//  ContentView.swift
//  Ask Tais
//
//  Created by Antonio Montani on 22/12/2022.
//

import SwiftUI
import UIKit

struct TextView: UIViewRepresentable {
    @Binding var text: String

    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.isEditable = true
        textView.isUserInteractionEnabled = true
        return textView
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = text
    }
}

struct ContentView: View {
    @State private var inputText = ""
    @State private var messages: [Message] = []
    
    var body: some View {
        VStack {
            NavigationView {
            List {
                ForEach(messages, id: \.id) { message in
                    Text(message.text)
                        .padding()
                        .background(message.isFromUser ? Color.green : Color.blue)
                        .cornerRadius(10)
                }
                
            }
            .navigationTitle("Ask Tais")
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    Menu {
                        Button(action: { exit(0) }) {
                            Label("Quit app", systemImage: "")
                        }
                    }
                    label: {
                        Label("Add", systemImage: "ellipsis.circle")
                    }
                }
            }
        }
            .onAppear {
                                // Add a "Hello" message to the list of messages when the app is first opened
                                self.messages.append(Message(id: UUID(), text: "Hello! I'm Tais, and I'm here to help you. Type what you'd like to say to your loved one and I will provide you with suggestions for saying it better.", isFromUser: false))
                            }
            .frame(maxHeight: .infinity)
            HStack {
                TextField("What do you want to say?", text: $inputText)
                Button(action: {
                    // Add a new message to the list with the user's input
                                        self.messages.append(Message(id: UUID(), text: self.inputText, isFromUser: true))
                    // Add a "Tais is thinking..." message to the list
                                       self.messages.append(Message(id: UUID(), text: "Tais is thinking...", isFromUser: false))
                    // Send a request to the backend with the input text
                    sendRequest(with: self.inputText) { response in
                        // Remove the "Tais is thinking..." message from the list
                                                self.messages.removeLast()
                        // Add a new message to the list with the response from the backend
                        self.messages.append(Message(id: UUID(), text: response, isFromUser: false))
                    }
                    // Clear the input field
                    self.inputText = ""
                }) {
                    Text("Ask Tais")
                }
            }
            .padding()
        }
    }
}

struct Message {
    var id: UUID
    var text: String
    var isFromUser: Bool
}

import Foundation

// Function to send a request to the backend
func sendRequest(with text: String, completion: @escaping (String) -> Void) {
    // Set up the URL request
    let endpoint = "https://afternoon-eyrie-23762.herokuapp.com/rewrite_feedback"
    let url = URL(string: endpoint)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    // Create the request body as JSON
    let body: [String: Any] = ["feedback_to_rewrite": text]
    let jsonData = try! JSONSerialization.data(withJSONObject: body)
    request.httpBody = jsonData

    // Send the request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }

        // Parse the response
        if let data = data, let response = String(data: data, encoding: .utf8) {
            completion(response)
        }
    }
    task.resume()
}
