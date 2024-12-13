//
//  ContentView.swift
//  llama chat
//
//  Created by Leonardo Mosimann conti on 12/12/24.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationStack {
            ChatSidebarView()
        }
    }
}

struct ChatView: View {
    let chatId: Int
    @State private var message: String = ""
    @State private var chatMessages: [ChatMessage] = []

    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatMessages) { message in
                        ChatBubbleView(message: message)
                    }
                }
                .padding()
            }

            // Message Input
            HStack(spacing: 12) {
                TextField("Ask anything...", text: $message)
                    .textFieldStyle(.roundedBorder)
                    .frame(height: 44)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 22)
                                .fill(Color.accentColor)
                        )
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
        .navigationTitle("Chat \(chatId)")
    }

    private func sendMessage() {
        guard !message.isEmpty else { return }

        let userMessage = ChatMessage(content: message, isUser: true)
        chatMessages.append(userMessage)

        message = ""

        // Simulate API response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = ChatMessage(
                content: "This is a simulated AI response. In the future, this will be replaced with actual API calls.",
                isUser: false
            )
            chatMessages.append(response)
        }
    }
}

struct ChatSidebarView: View {
    var body: some View {
        List {
            ForEach(1...5, id: \.self) { index in
                NavigationLink {
                    ChatView(chatId: index)
                } label: {
                    Label("Chat \(index)", systemImage: "bubble.left.fill")
                }
            }
        }
        .navigationTitle("Chats")
    }
}

// Models and supporting views
struct ChatMessage: Identifiable {
    let id = UUID()
    let content: String
    let isUser: Bool
    let timestamp = Date()
}

struct ChatBubbleView: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer() }

            Text(message.content)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(message.isUser ? Color.purple.opacity(0.8) : Color.gray.opacity(0.2))
                )
                .foregroundStyle(message.isUser ? .white : .primary)

            if !message.isUser { Spacer() }
        }
    }
}

#Preview {
    ContentView()
}
