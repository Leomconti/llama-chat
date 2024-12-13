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
    // Consolidate related state variables
    private struct ViewState {
        var message: String = ""
        var chatMessages: [ChatMessage] = []
        var isTyping = false
        var showMediaButtons = true
        var keyboardOffset: CGFloat = 0
        var keyboardHeight: CGFloat = 0
        var scrollOffset: CGFloat = 0
        var dragOffset: CGFloat = 0

        // Add computed properties
        var shouldShowKeyboard: Bool {
            keyboardOffset > 0
        }

        var effectiveOffset: CGFloat {
            max(0, keyboardOffset + dragOffset)
        }
    }

    let chatId: Int
    @State private var viewState = ViewState()
    @FocusState private var isInputFocused: Bool
    @GestureState private var dragState: CGFloat = 0

    // Constants moved to top for better maintainability
    private enum Constants {
        static let minInputHeight: CGFloat = 36
        static let dismissThreshold: CGFloat = 100
        static let buttonSize: CGFloat = 44 // Following Apple's touch target guidelines
    }

    var body: some View {
        VStack(spacing: 0) {
            messageList
            inputArea
        }
        .navigationTitle("Chat \(chatId)")
        .navigationBarTitleDisplayMode(.inline)
        .coordinateSpace(name: "chat")
        .onChange(of: viewState.keyboardOffset) { _, newOffset in
            withAnimation(.spring(
                response: AnimationConstants.springResponse,
                dampingFraction: AnimationConstants.springDamping
            )) {
                viewState.dragOffset = newOffset
            }
        }
        .onChange(of: isInputFocused) { _, isFocused in
            if !isFocused {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    viewState.keyboardOffset = 0
                    viewState.dragOffset = 0
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
                viewState.keyboardHeight = keyboardFrame.height
            }

            NotificationCenter.default.addObserver(
                forName: UIResponder.keyboardWillHideNotification,
                object: nil,
                queue: .main
            ) { _ in
                viewState.keyboardHeight = 0
            }
        }
    }

    // Break down into smaller views for better maintainability
    private var messageList: some View {
        ScrollView {
            GeometryReader { geometry in
                Color.clear.preference(
                    key: ScrollOffsetPreferenceKey.self,
                    value: geometry.frame(in: .named("scroll")).origin.y
                )
            }
            .frame(height: 0)

            LazyVStack(spacing: 16) {
                ForEach(viewState.chatMessages) { message in
                    ChatBubbleView(message: message)
                        .transition(AnimationConstants.Transitions.messageTransition)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 24)
        }
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ScrollOffsetPreferenceKey.self) { value in
            viewState.scrollOffset = value
        }
        .gesture(
            DragGesture()
                .updating($dragState) { value, state, _ in
                    if viewState.scrollOffset >= 0 && isInputFocused {
                        state = value.translation.height

                        if value.location.y >= UIScreen.main.bounds.height - 100 {
                            withAnimation(.spring(response: 0.2, dampingFraction: 0.7)) {
                                viewState.keyboardOffset = max(0, value.translation.height)
                            }
                        }
                    }
                }
                .onEnded { value in
                    let dismissThreshold: CGFloat = 100
                    if viewState.keyboardOffset > dismissThreshold {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            isInputFocused = false
                            viewState.keyboardOffset = 0
                        }
                    } else {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            viewState.keyboardOffset = 0
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
                            viewState.keyboardOffset = 0
                            viewState.dragOffset = 0
                        }
                    }
                }
        )
    }

    private var inputArea: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(alignment: .bottom, spacing: 12) {
                messageInput
                actionButtons
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial)
        }
        .offset(y: viewState.keyboardOffset)
    }

    private var messageInput: some View {
        TextField("Message", text: $viewState.message, axis: .vertical)
            .focused($isInputFocused)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .frame(minHeight: Constants.minInputHeight)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(.secondarySystemBackground))
            )
            .onChange(of: viewState.message) { _, newValue in
                withAnimation(.spring(duration: AnimationConstants.springResponse)) {
                    viewState.showMediaButtons = newValue.isEmpty
                }
            }
            .accessibilityLabel("Message input field")
            .accessibilityHint("Double tap to enter your message")
    }

    private var actionButtons: some View {
        HStack(spacing: 16) {
            if viewState.showMediaButtons {
                mediaButtons
            } else {
                sendButton
            }
        }
        .animation(
            .spring(duration: AnimationConstants.springResponse),
            value: viewState.showMediaButtons
        )
    }

    private var mediaButtons: some View {
        HStack(spacing: 12) {
            Button(action: {}) {
                Image(systemName: "photo")
                    .font(.system(size: 20))
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    .foregroundColor(.accentColor)
            }

            Button(action: {}) {
                Image(systemName: "mic")
                    .font(.system(size: 20))
                    .frame(width: Constants.buttonSize, height: Constants.buttonSize)
                    .foregroundColor(.accentColor)
            }
        }
    }

    private var sendButton: some View {
        Button(action: sendMessage) {
            Image(systemName: "arrow.up.circle.fill")
                .font(.system(size: 30))
                .foregroundColor(.accentColor)
                .frame(width: Constants.buttonSize, height: Constants.buttonSize)
        }
        .transition(AnimationConstants.Transitions.buttonTransition)
        .accessibilityLabel("Send message")
        .accessibilityHint("Double tap to send your message")
    }

    func sendMessage() {
        guard !viewState.message.isEmpty else { return }

        let userMessage = ChatMessage(content: viewState.message, isUser: true)
        viewState.chatMessages.append(userMessage)

        viewState.message = ""

        // Simulate API response
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            let response = ChatMessage(
                content: "This is a simulated AI response. In the future, this will be replaced with actual API calls.",
                isUser: false
            )
            viewState.chatMessages.append(response)
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

// Create a dedicated KeyboardManager
class KeyboardManager: ObservableObject {
    @Published var keyboardHeight: CGFloat = 0

    init() {
        setupKeyboardObservers()
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] notification in
            guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            self?.keyboardHeight = keyboardFrame.height
        }

        NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            self?.keyboardHeight = 0
        }
    }
}

class ChatManager: ObservableObject {
    @Published private(set) var messages: [ChatMessage] = []

    func sendMessage(_ content: String) {
        let message = ChatMessage(content: content, isUser: true)
        messages.append(message)

        // Simulate API response (replace with actual API call)
        Task {
            try? await Task.sleep(for: .seconds(1))
            await MainActor.run {
                let response = ChatMessage(
                    content: "AI response...",
                    isUser: false
                )
                messages.append(response)
            }
        }
    }
}

protocol ChatManagerProtocol {
    var messages: [ChatMessage] { get }
    func sendMessage(_ content: String) async throws
}

// Make ChatManager conform to this protocol for better testing

#Preview {
    ContentView(username: "JohnDoe")
        .environmentObject(UserSettings())
}
