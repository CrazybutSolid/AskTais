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
    @State private var showThumbsDownSheet = false
    @State private var feedbackText = ""
    @State private var showThanksForFeedback = false

    
    var body: some View {
        VStack {
            NavigationView {
            List {
                ForEach(messages, id: \.id) { message in

                    Text(message.text)
                        .padding()
                        .background(message.isFromUser ? Color.green : Color.blue)
                        .cornerRadius(10)
                    if !message.isFromUser && message.isReplyFromBackEnd {
                            HStack {
                                ThumbsUpButton(message: message)
                                Spacer()
                                ThumbsDownButton(message: message, showThumbsDownSheet: $showThumbsDownSheet, reviewText: $feedbackText)
                            }
                        }
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
                self.messages.append(Message(id: UUID(), text: "Hello! I'm Tais, and I'm here to help you. Type what you'd like to say to your loved one and I will provide you with suggestions for saying it better.", isFromUser: false, isReplyFromBackEnd: false, responseId: "0"))
                self.messages.append(Message(id: UUID(), text: "Some common examples: 'you never listen to me', 'i do everything here and you never help', 'you're always to busy for us','you don't support me when i need you', 'you don't understand me'", isFromUser: false, isReplyFromBackEnd: false, responseId: "0"))
                            }
            .frame(maxHeight: .infinity)
            HStack {
                TextField("What do you want to say?", text: $inputText)
                Button(action: {
                    // Add a new message to the list with the user's input
                    self.messages.append(Message(id: UUID(), text: self.inputText, isFromUser: true, isReplyFromBackEnd: false, responseId:"0"))
                    // Add a "Tais is thinking..." message to the list
                    self.messages.append(Message(id: UUID(), text: "Tais is thinking...", isFromUser: false, isReplyFromBackEnd: false,responseId:"0"))
                    // Send a request to the backend with the input text
                    sendRequest(with: self.inputText) { responseText, id in
                        // Remove the "Tais is thinking..." message from the list
                                                self.messages.removeLast()
                        // Add a new message to the list with the response from the backend
                        self.messages.append(Message(id: UUID(), text: responseText, isFromUser: false, isReplyFromBackEnd: true, responseId: id))
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
    var isReplyFromBackEnd: Bool
    var responseId: String
}

// Struct to parse the response from the backend
struct ResponseData: Decodable {
    let rewritten_feedback: String
    let id: String
}

struct ThumbsUpButton: View {
    var message: Message
    @State private var isThumbsUpSent = false

    var body: some View {
        Button(action: {
            sendThumbsUpNotification(with: message) { success in
                if success {
                    self.isThumbsUpSent = true
                }
            }
        }) {
            Image(systemName: "hand.thumbsup")
                .imageScale(.large)
                .font(.system(size: 20))
                .foregroundColor(isThumbsUpSent ? .green : .black)
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}


struct ThumbsDownButton: View {
    var message: Message
    @Binding var showThumbsDownSheet: Bool
    @Binding var reviewText: String
    @State private var isThumbsDownSent = false

    var body: some View {
        Button(action: {
            // Show the feedback prompt
            self.showThumbsDownSheet = true
        }) {
            Image(systemName: "hand.thumbsdown")
                .imageScale(.large)
                .font(.system(size: 20))
                .foregroundColor(isThumbsDownSent ? .green : .black)

        }
        .sheet(isPresented: $showThumbsDownSheet) {
            VStack {
                Text("Thanks for the feedback! How can we make it better?")
                TextField("Enter your feedback here", text: $reviewText)
                    .frame(width: 250, height: 50)
                    .frame(alignment: .center)
                Button(action: {
                    // Send the feedback to the backend
                    sendThumbsDownNotification(with: reviewText, message: message)
                    // Close the feedback prompt
                    self.showThumbsDownSheet = false
                    self.isThumbsDownSent = true
                }) {
                    Text("Submit Feedback")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
                Button(action: {
                    // Close the feedback prompt
                    self.showThumbsDownSheet = false
                }) {
                    Text("Close")
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(8)
                .padding(.horizontal)
            }
        }
        .buttonStyle(BorderlessButtonStyle())
    }
}



import Foundation

// Function to send a request to the backend
func sendRequest(with text: String, completion: @escaping (String,String) -> Void) {
    // Set up the URL request
    let endpoint = "https://afternoon-eyrie-23762.herokuapp.com/rewrite_feedback"
    let url = URL(string: endpoint)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

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
                if let data = data, let responseData = try?
                    JSONDecoder().decode(ResponseData.self, from: data) {
                    let responseText = responseData.rewritten_feedback
                    let id = responseData.id
                    completion(responseText, id)
                }
    }
    task.resume()
}

// Function to send a notification to the backend about a thumbs up
func sendThumbsUpNotification(with message: Message, completion: @escaping (Bool) -> Void) {
    // Set up the URL request
    let endpoint = "https://afternoon-eyrie-23762.herokuapp.com/rewritten_feedback_review"
    let url = URL(string: endpoint)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")
    
    // Create the request body as JSON
    let body: [String: Any] = ["id": message.responseId]
    let jsonData = try! JSONSerialization.data(withJSONObject: body)
    request.httpBody = jsonData
    
    // Send the request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            completion(false)
            return
        }
        
        // Check the HTTP status code of the response
        if let httpResponse = response as? HTTPURLResponse {
            if httpResponse.statusCode == 200 {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    task.resume()
}


func sendThumbsDownNotification(with review: String, message: Message) {
    // Set up the URL request
    let endpoint = "https://afternoon-eyrie-23762.herokuapp.com/rewritten_feedback_review"
    let url = URL(string: endpoint)!
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")
    request.addValue("application/json", forHTTPHeaderField: "Accept")

    // Create the request body as JSON
    let body: [String: Any] = ["id": message.responseId, "review": review]
    let jsonData = try! JSONSerialization.data(withJSONObject: body)
    request.httpBody = jsonData

    // Send the request
    let task = URLSession.shared.dataTask(with: request) { data, response, error in
        if let error = error {
            print("Error: \(error)")
            return
        }

        // Parse the response
        if let response = response as? HTTPURLResponse,
           response.statusCode == 200 {
            print("Successfully sent feedback")
        } else {
            print("Error sending feedback")
        }
    }
    task.resume()
}
