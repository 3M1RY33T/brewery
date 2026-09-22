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

struct InstallSheet: View {
    @Binding var name: String
    @Binding var kind: PackageKind
    let cancel: () -> Void
    let confirm: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("Install Package")
                .font(.title2)
                .fontWeight(.semibold)

            TextField("Package name", text: $name)
                .textFieldStyle(.roundedBorder)

            Picker("Type", selection: $kind) {
                ForEach(PackageKind.allCases) { kind in
                    Text(kind.title).tag(kind)
                }
            }
            .pickerStyle(.segmented)

            Text((["brew"] + BrewAction.install(name: name.isEmpty ? "<name>" : name, kind: kind).arguments).joined(separator: " "))
                .font(.system(.callout, design: .monospaced))
                .foregroundColor(.secondary)
                .textSelection(.enabled)

            HStack {
                Spacer()
                Button("Cancel", action: cancel)
                    .keyboardShortcut(.cancelAction)
                Button("Review Command", action: confirm)
                    .keyboardShortcut(.defaultAction)
                    .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(22)
        .frame(width: 420)
    }
}
