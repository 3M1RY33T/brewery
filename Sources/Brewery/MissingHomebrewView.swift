import BreweryCore
import SwiftUI

struct MissingHomebrewView: View {
    let report: BrewDetectionReport

    private let installCommand = "/bin/bash -c \"$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)\""

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Image("brewery-logo", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: 82, height: 82)
                .accessibilityLabel("Brewery")

            Text("Homebrew Not Found")
                .font(.largeTitle)
                .fontWeight(.semibold)

            Text("Brewery needs an existing Homebrew installation before it can manage packages.")
                .foregroundColor(.secondary)

            VStack(alignment: .leading, spacing: 8) {
                Text("Checked")
                    .font(.headline)
                ForEach(report.checkedPaths, id: \.self) { path in
                    Label(path, systemImage: "magnifyingglass")
                        .foregroundColor(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Official install command")
                    .font(.headline)
                Text(installCommand)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.wellBackground)
                    .cornerRadius(6)
            }

            if let lookupError = report.lookupError {
                Text(lookupError)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(32)
        .frame(maxWidth: 720, maxHeight: .infinity, alignment: .center)
    }
}
