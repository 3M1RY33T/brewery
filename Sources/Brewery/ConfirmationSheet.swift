import BreweryCore
import SwiftUI

struct ConfirmationSheet: View {
    let action: BrewAction
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(action.title)
                .font(.title2)
                .fontWeight(.semibold)

            Text("Brewery will run this Homebrew command:")
                .foregroundColor(.secondary)

            // Upgrading everything names every package, so the command can
            // run to many lines; cap the box rather than the dialog.
            ScrollView {
                Text(action.commandDisplay)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 220)
            .fixedSize(horizontal: false, vertical: true)
            .background(Color(nsColor: .textBackgroundColor))
            .cornerRadius(6)

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.cancelAction)
                Button("Run Command", action: confirm)
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(22)
        .frame(width: 460)
    }
}
