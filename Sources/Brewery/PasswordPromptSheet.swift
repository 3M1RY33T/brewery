import BreweryCore
import Foundation
import SwiftUI

/// Asks for the administrator password sudo wants while a Homebrew command
/// runs. The password answers that one prompt and is never stored.
struct PasswordPromptSheet: View {
    let request: PasswordRequest
    let cancel: () -> Void
    let submit: (String) -> Void

    @State private var password = ""
    @FocusState private var isPasswordFocused: Bool

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

                if request.isRetry {
                    Text("That password didn’t work. Try again.")
                        .font(.callout)
                        .foregroundColor(.red)
                }
            }

            Text("Brewery hands it to sudo for this command only and never saves it.")
                .font(.caption)
                .foregroundColor(.secondary)

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

    private func submitIfEntered() {
        guard !password.isEmpty else { return }
        submit(password)
    }
}
