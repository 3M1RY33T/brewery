import CryptoKit
import Foundation
import LocalAuthentication
import Security

/// What came of trying to unlock the saved password with Touch ID.
public enum PasswordVaultUnlock: Equatable {
    case password(String)
    /// The user cancelled or chose to type the password, or Touch ID cannot
    /// be used right now (lid closed, locked out). The saved password stays.
    case declined
    /// The saved password can never be unlocked again, for the reason given
    /// (fingerprints changed, another Mac, a damaged file). It should be
    /// forgotten.
    case invalidated(String)
}

/// Keeps the administrator password so Touch ID can answer sudo.
public protocol PasswordVaulting: AnyObject {
    /// Touch ID is set up and usable on this Mac right now.
    var isAvailable: Bool { get }
    var hasSavedPassword: Bool { get }
    func save(_ password: String) throws
    /// Shows the Touch ID prompt; `reason` completes "Brewery is trying to".
    func unlock(reason: String) async -> PasswordVaultUnlock
    func forget()
}

/// Saves the password encrypted to a Secure Enclave key that only works
/// after a Touch ID match against the fingerprints enrolled when it was
/// saved. The file alone is useless: decrypting it takes this Mac's Secure
/// Enclave and one of those fingerprints.
///
/// The key lives in the file in its wrapped form rather than in the
/// keychain, which an ad hoc signed app cannot use for Secure Enclave keys.
public final class SecureEnclavePasswordVault: PasswordVaulting {
    private let fileURL: URL

    public init(fileURL: URL = SecureEnclavePasswordVault.defaultFileURL()) {
        self.fileURL = fileURL
    }

    public var isAvailable: Bool {
        SecureEnclave.isAvailable
            && LAContext().canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: nil)
    }

    public var hasSavedPassword: Bool {
        FileManager.default.fileExists(atPath: fileURL.path)
    }

    public func save(_ password: String) throws {
        guard let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            [.privateKeyUsage, .biometryCurrentSet],
            nil
        ) else {
            throw PasswordVaultError.accessControlUnavailable
        }
        let key = try SecureEnclave.P256.KeyAgreement.PrivateKey(accessControl: access)
        let sealed = try SealedPassword.seal(password, to: key.publicKey, enclaveKey: key.dataRepresentation)

        try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try JSONEncoder().encode(sealed).write(to: fileURL, options: [.atomic])
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: fileURL.path)
    }

    public func unlock(reason: String) async -> PasswordVaultUnlock {
        guard let data = try? Data(contentsOf: fileURL),
              let sealed = try? JSONDecoder().decode(SealedPassword.self, from: data)
        else {
            return .invalidated("the saved password file could not be read")
        }

        let context = LAContext()
        context.localizedFallbackTitle = "Enter Password"
        do {
            // Biometrics only, on purpose: the key accepts nothing but a
            // fingerprint, so a policy that also took the login password
            // would let that through here and then fail at the key below.
            try await context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason)
        } catch LAError.biometryNotEnrolled {
            return .invalidated("no fingerprints are enrolled")
        } catch {
            return .declined
        }

        do {
            let key = try SecureEnclave.P256.KeyAgreement.PrivateKey(
                dataRepresentation: sealed.enclaveKey,
                authenticationContext: context
            )
            return .password(try sealed.open { try key.sharedSecretFromKeyAgreement(with: $0) })
        } catch {
            // Touch ID matched, yet the key refused. Every cause is lasting:
            // fingerprints changed, or the file came from another Mac.
            return .invalidated("the Secure Enclave key refused: \(error.localizedDescription)")
        }
    }

    public func forget() {
        try? FileManager.default.removeItem(at: fileURL)
    }

    public static func defaultFileURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? URL(fileURLWithPath: NSTemporaryDirectory())
        return base
            .appendingPathComponent("Brewery", isDirectory: true)
            .appendingPathComponent("touch-id-password.json")
    }
}

/// The password sealed with ECIES: a one-off key agrees a secret with the
/// Secure Enclave key, and AES-GCM encrypts under a key derived from it.
/// Sealing needs only the public key, so saving never asks for Touch ID.
struct SealedPassword: Codable, Equatable {
    /// The Secure Enclave key, wrapped so only this Mac's enclave can use it.
    let enclaveKey: Data
    let ephemeralPublicKey: Data
    let box: Data

    static func seal(
        _ password: String,
        to publicKey: P256.KeyAgreement.PublicKey,
        enclaveKey: Data
    ) throws -> SealedPassword {
        let ephemeral = P256.KeyAgreement.PrivateKey()
        let key = derivedKey(try ephemeral.sharedSecretFromKeyAgreement(with: publicKey), ephemeral: ephemeral.publicKey)
        guard let box = try AES.GCM.seal(Data(password.utf8), using: key).combined else {
            throw PasswordVaultError.sealFailed
        }
        return SealedPassword(enclaveKey: enclaveKey, ephemeralPublicKey: ephemeral.publicKey.rawRepresentation, box: box)
    }

    /// `agree` is the private half of the key agreement; for the Secure
    /// Enclave key it is the step Touch ID guards.
    func open(agree: (P256.KeyAgreement.PublicKey) throws -> SharedSecret) throws -> String {
        let ephemeral = try P256.KeyAgreement.PublicKey(rawRepresentation: ephemeralPublicKey)
        let key = Self.derivedKey(try agree(ephemeral), ephemeral: ephemeral)
        let password = try AES.GCM.open(AES.GCM.SealedBox(combined: box), using: key)
        return String(decoding: password, as: UTF8.self)
    }

    private static func derivedKey(_ secret: SharedSecret, ephemeral: P256.KeyAgreement.PublicKey) -> SymmetricKey {
        secret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: ephemeral.rawRepresentation,
            sharedInfo: Data("dev.brewery.sudo-password".utf8),
            outputByteCount: 32
        )
    }
}

enum PasswordVaultError: LocalizedError {
    case accessControlUnavailable
    case sealFailed

    var errorDescription: String? {
        switch self {
        case .accessControlUnavailable:
            return "Touch ID protection could not be set up for the password."
        case .sealFailed:
            return "The password could not be encrypted."
        }
    }
}
