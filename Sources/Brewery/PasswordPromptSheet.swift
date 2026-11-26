import BreweryCore
import Foundation
import SwiftUI

/// Asks for the administrator password sudo wants while a Homebrew command
/// runs. Unless the user opts into Touch ID, the password answers that one
/// prompt and is never stored.
struct PasswordPromptSheet: View {
    let request: PasswordRequest
    let cancel: () -> Void
    /// The password, and the Touch ID checkbox or nil when none was shown.
    let submit: (String, Bool?) -> Void

    @State private var password = ""
    @State private var usesTouchID: Bool
    @FocusState private var isPasswordFocused: Bool

    init(request: PasswordRequest, cancel: @escaping () -> Void, submit: @escaping (String, Bool?) -> Void) {
        self.request = request
        self.cancel = cancel
        self.submit = submit
        _usesTouchID = State(initialValue: request.usesTouchID)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 10) {
                Image(systemName: "lock.fill")
                    .font(.title2)
                    .foregroundColor(.secondary)
                Text("Password Required")
                    .font(.title2)
                    .fontWeight(.semibold)
            }

            Text("“\(request.actionTitle)” needs administrator access. Enter the login password for “\(NSUserName())” so Homebrew can continue.")
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 6) {
                SecureField("Password", text: $password)
                    .textFieldStyle(.roundedBorder)
                    .focused($isPasswordFocused)
                    .onSubmit(submitIfEntered)

                if let notice = request.notice {
                    Text(message(for: notice))
                        .font(.callout)
                        .foregroundColor(.red)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                if request.offersTouchID {
                    Toggle("Use Touch ID next time", isOn: $usesTouchID)
                        .toggleStyle(.checkbox)
                }

                Text(savesPassword
                    ? "Once the command succeeds, Brewery saves the password encrypted so only your fingerprint can unlock it."
                    : "Brewery hands it to sudo for this command only and never saves it.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.cancelAction)
                Button("Continue", action: submitIfEntered)
                    .keyboardShortcut(.defaultAction)
                    .disabled(password.isEmpty)
            }
        }
        .padding(22)
        .frame(width: 460)
        .onAppear { isPasswordFocused = true }
    }

    private var savesPassword: Bool {
        request.offersTouchID && usesTouchID
    }

    private func message(for notice: PasswordRequest.Notice) -> String {
        switch notice {
        case .wrongPassword:
            return "That password didn’t work. Try again."
        case .savedPasswordRejected:
            return "Your saved password no longer works, so Brewery forgot it. Enter your current password."
        case .savedPasswordUnreadable:
            return "Touch ID can no longer unlock your saved password, so Brewery forgot it. Enter it again."
        }
    }

    private func submitIfEntered() {
        guard !password.isEmpty else { return }
        submit(password, request.offersTouchID ? usesTouchID : nil)
    }
}
