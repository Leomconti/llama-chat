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
    let username: String

    var body: some View {
        NavigationStack {
            ChatSidebarView(username: username)
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
    @FocusState private var isInputFocused: Bool
    @State private var keyboardOffset: CGFloat = 0
    @State private var dragOffset: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var scrollOffset: CGFloat = 0
    @GestureState private var dragState: CGFloat = 0

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                GeometryReader { geometry in
                    Color.clear.preference(
                        key: ScrollOffsetPreferenceKey.self,
                        value: geometry.frame(in: .named("scroll")).origin.y
                    )
                }
                .frame(height: 0)

                LazyVStack(spacing: 16) {
                    ForEach(chatMessages) { message in
                        ChatBubbleView(message: message)
                            .transition(.moveAndFade)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .coordinateSpace(name: "scroll")
            .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
                scrollOffset = value
            }
            .gesture(
                DragGesture()
                    .updating($dragState) { value, state, _ in
                        if scrollOffset >= 0 && isInputFocused {
                            state = value.translation.height

                            if value.location.y >= UIScreen.main.bounds.height - 100 {
                                withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                    keyboardOffset = max(0, value.translation.height)
                                }
                            }
                        }
                    }
                    .onEnded { value in
                        let dismissThreshold: CGFloat = 100
                        if keyboardOffset > dismissThreshold {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isInputFocused = false
                                keyboardOffset = 0
                            }
                        } else {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                keyboardOffset = 0
                            }
                        }
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded { _ in
                        if isInputFocused {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                isInputFocused = false
                                keyboardOffset = 0
                                dragOffset = 0
                            }
                        }
                    }
            )

            // Input area
            VStack(spacing: 0) {
                Divider()
                HStack(alignment: .bottom, spacing: 12) {
                    // Input Field
                    TextField("Message", text: $message, axis: .vertical)
                        .focused($isInputFocused)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .frame(minHeight: 36)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(Color(.secondarySystemBackground))
                        )
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
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color(.secondarySystemBackground))
                                    )
                            }
                            .transition(AnimationConstants.Transitions.buttonTransition)
                            .pressAnimation()

                            Button(action: { /* Mic action */ }) {
                                Image(systemName: "mic.fill")
                                    .font(.system(size: 20))
                                    .foregroundStyle(.gray)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color(.secondarySystemBackground))
                                    )
                            }
                            .transition(AnimationConstants.Transitions.buttonTransition)
                            .pressAnimation()
                        } else {
                            Button(action: sendMessage) {
                                Image(systemName: "arrow.up")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                                    .frame(width: 36, height: 36)
                                    .background(
                                        Circle()
                                            .fill(Color.accentColor.gradient)
                                    )
                            }
                            .transition(AnimationConstants.Transitions.buttonTransition)
                            .pressAnimation()
                        }
                    }
                    .animation(.spring(duration: 0.3), value: showMediaButtons)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(.ultraThinMaterial)
            }
            .offset(y: keyboardOffset)
        }
        .navigationTitle("Chat \(chatId)")
        .navigationBarTitleDisplayMode(.inline)
        .coordinateSpace(name: "chat")
        .onChange(of: keyboardOffset) { _, newOffset in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                dragOffset = newOffset
            }
        }
        .onChange(of: isInputFocused) { _, isFocused in
            if !isFocused {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    keyboardOffset = 0
                    dragOffset = 0
                }
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillShowNotification,
                object: nil,
                queue: .main
            ) { notification in
                guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else {
                    return
                }
                keyboardHeight = keyboardFrame.height
            }

            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                keyboardHeight = 0
            }
        }
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

struct ScrollOffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct ChatSidebarView: View {
    let username: String
    @EnvironmentObject private var userSettings: UserSettings
    @State private var showingNewChatSheet = false
    @State private var showingEditSheet = false
    @State private var selectedChatId: Int?

    var body: some View {
        List {
            // Username section
            Section {
                HStack {
                    Image(systemName: "person.circle.fill")
                        .font(.title)
                        .foregroundStyle(.purple)
                    Text(username)
                        .font(.headline)
                    Spacer()
                    Button(action: { userSettings.logout() }) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .foregroundStyle(.red)
                    }
                }
            }

            // Existing chats section
            Section {
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
                messageContent
                    .modifier(MessageAnimationModifier(message: message))
            } else {
                messageContent
                    .modifier(MessageAnimationModifier(message: message))
                Spacer()
            }
        }
    }

    private var messageContent: some View {
        Text(message.content)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(message.isUser ? Color.accentColor.gradient : Color(.secondarySystemBackground).gradient)
            )
            .foregroundStyle(message.isUser ? .white : .primary)
            .shadow(color: .black.opacity(0.1), radius: 3, x: 0, y: 2)
            .pressAnimation()
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
    ContentView(username: "JohnDoe")
        .environmentObject(UserSettings())
}
