//
//  ContentView.swift
//  llama chat
//
//  Created by Leonardo Mosimann conti on 12/12/24.
//

import SwiftUI
import UIKit

// MARK: - Extensions
extension AnyTransition {
    static var moveAndFade: AnyTransition {
        .asymmetric(
            insertion: .scale(scale: 0.9)
                .combined(with: .opacity)
                .combined(with: .offset(y: 20)),
            removal: .scale(scale: 0.8).combined(with: .opacity)
        )
    }
}

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
    @State private var isTyping = false
    @State private var inputHeight: CGFloat = 44
    @State private var showMediaButtons = true
    var body: some View {
        VStack(spacing: 0) {
            // Chat Messages
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(chatMessages) { message in
                        ChatBubbleView(message: message)
                            .transition(.moveAndFade)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .background(
                Color(.systemBackground)
                    .overlay(
                        Pattern()
                            .opacity(0.03)
                    )
            )

            // Updated Message Input
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 12) {
                    // Input Field
                    TextField("Message", text: $message, axis: .vertical)
                        .padding(.horizontal, 16)
                        .frame(height: inputHeight)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                        .onChange(of: message) { oldValue, newValue in
                            withAnimation(.spring(duration: 0.3)) {
                                showMediaButtons = newValue.isEmpty
                            }
                        }

                    // Dynamic Buttons
                    HStack(spacing: 16) {
                        if showMediaButtons {
                            Button(action: { /* Camera action */ }) {
                                Image(systemName: "camera.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.gray)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))

                            Button(action: { /* Mic action */ }) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.gray)
                            }
                            .transition(.move(edge: .trailing).combined(with: .opacity))
                        } else {
                            Button(action: sendMessage) {
                                Circle()
                                    .fill(Color.accentColor)
                                    .frame(width: 44, height: 44)
                                    .overlay(
                                        Image(systemName: "arrow.up")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    )
                            }
                            .transition(.scale.combined(with: .opacity))
                        }
                    }
                    .animation(.spring(duration: 0.3), value: showMediaButtons)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.ultraThinMaterial)
            }
        }
        .navigationTitle("Chat \(chatId)")
        .navigationBarTitleDisplayMode(.inline)
    }

    func sendMessage() {
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
    @State private var showingNewChatSheet = false
    @State private var showingEditSheet = false
    @State private var selectedChatId: Int?

    var body: some View {
        List {
            ForEach(1...5, id: \.self) { index in
                NavigationLink {
                    ChatView(chatId: index)
                } label: {
                    ChatRowView(index: index)
                        .swipeActions {
                            Button {
                                selectedChatId = index
                                showingEditSheet = true
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                }
            }
        }
        .navigationTitle("Chats")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingNewChatSheet = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 22))
                }
            }
        }
        .sheet(isPresented: $showingNewChatSheet) {
            NewChatView()
        }
        .sheet(isPresented: $showingEditSheet) {
            EditChatView(chatId: selectedChatId ?? 1)
        }
        .background(
            LinearGradient(
                colors: [Color(.systemBackground), Color(.secondarySystemBackground)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }
}

struct ChatRowView: View {
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .blue],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)

                Text("\(index)")
                    .foregroundColor(.white)
                    .font(.headline)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("Chat \(index)")
                    .font(.headline)
                Text("Last message preview...")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct NewChatView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var chatName = ""

    var body: some View {
        NavigationView {
            Form {
                TextField("Chat Name", text: $chatName)
            }
            .navigationTitle("New Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        createNewChat()
                        dismiss()
                    }
                    .disabled(chatName.isEmpty)
                }
            }
        }
    }

    private func createNewChat() {
        // TODO: API call to create new chat
        print("Creating new chat: \(chatName)")
    }
}

struct EditChatView: View {
    let chatId: Int
    @Environment(\.dismiss) private var dismiss
    @State private var chatName: String
    @State private var description = ""

    init(chatId: Int) {
        self.chatId = chatId
        _chatName = State(initialValue: "Chat \(chatId)")
    }

    var body: some View {
        NavigationView {
            Form {
                TextField("Chat Name", text: $chatName)
                TextField("Description", text: $description)

                Button("Change Image") {
                    // TODO: Image picker
                }
            }
            .navigationTitle("Edit Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                        dismiss()
                    }
                }
            }
        }
    }

    private func saveChanges() {
        // TODO: API call to save changes
        print("Saving changes for chat \(chatId)")
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
        HStack(alignment: .bottom, spacing: 8) {
            if message.isUser {
                Spacer()
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.accentColor.gradient)
                    )
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            } else {
                Text(message.content)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.secondarySystemBackground))
                    )
                    .foregroundStyle(.primary)
                Spacer()
            }
        }
    }
}

// New Supporting Views
struct Pattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let size = CGSize(width: 20, height: 20)
                let xCount = Int(geometry.size.width / size.width)
                let yCount = Int(geometry.size.height / size.height)

                for x in 0...xCount {
                    for y in 0...yCount {
                        let dot = Circle()
                            .size(width: 2, height: 2)
                            .path(in: CGRect(
                                x: CGFloat(x) * size.width,
                                y: CGFloat(y) * size.height,
                                width: 2,
                                height: 2
                            ))
                        path.addPath(dot)
                    }
                }
            }
            .fill(Color.gray)
        }
    }
}


#Preview {
    ContentView()
}
