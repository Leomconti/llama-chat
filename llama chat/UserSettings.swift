import SwiftUI

class UserSettings: ObservableObject {
    @AppStorage("username") var username: String = ""
    @AppStorage("isLoggedIn") var isLoggedIn: Bool = false

    func login(with username: String) {
        self.username = username
        self.isLoggedIn = true
    }

    func logout() {
        self.username = ""
        self.isLoggedIn = false
    }
}
