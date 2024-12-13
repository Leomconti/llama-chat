import SwiftUI

struct WelcomeView: View {
    @State private var username = ""
    @State private var isAnimating = false
    @State private var navigateToChat = false
    @EnvironmentObject private var userSettings: UserSettings

    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Logo/Title Area
                VStack(spacing: 20) {
                    Text("Llama Chat")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)
                }
                .padding(.top, 60)

                Spacer()

                // Login Area
                VStack(spacing: 20) {
                    TextField("Enter your username", text: $username)
                        .textFieldStyle(.roundedBorder)
                        .padding(.horizontal, 40)
                        .textInputAutocapitalization(.never)
                        .opacity(isAnimating ? 1 : 0)
                        .offset(y: isAnimating ? 0 : 20)

                    Button(action: login) {
                        Text("Continue")
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [.purple, .blue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(Capsule())
                            .padding(.horizontal, 40)
                    }
                    .disabled(username.isEmpty)
                    .opacity(isAnimating ? 1 : 0)
                    .offset(y: isAnimating ? 0 : 20)
                }

                Spacer()
            }
            .navigationDestination(isPresented: $navigateToChat) {
                ContentView(username: username)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }

    private func login() {
        guard !username.isEmpty else { return }
        userSettings.login(with: username)
        navigateToChat = true
    }
}

#Preview {
    WelcomeView()
        .environmentObject(UserSettings())
}
