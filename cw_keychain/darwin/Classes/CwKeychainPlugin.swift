import Foundation

#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif


private struct KeychainDataWrapper: Codable {
    let name: String
    let walletTypeRaw: Int64
    let seed: String
    let networkRaw: Int64
    let version: Int64
    let derivationTypeRaw: Int64
    let derivationPath: String?
    let seedTypeRaw: Int64?
    let blockHeight: Int64?
    let passphrase: String?

    var accountId: String {
        return "\(name)_\(walletTypeRaw)"
    }

    init(from pigeonData: KeychainDataV1) {
        self.name = pigeonData.name
        self.walletTypeRaw = pigeonData.walletTypeRaw
        self.seed = pigeonData.seed
        self.derivationTypeRaw = pigeonData.derivationTypeRaw
        self.derivationPath = pigeonData.derivationPath
        self.version = pigeonData.version
        self.networkRaw = pigeonData.networkRaw
        self.seedTypeRaw = pigeonData.seedTypeRaw
        self.blockHeight = pigeonData.blockHeight
        self.passphrase = pigeonData.passphrase
    }

    func toPigeonData() -> KeychainDataV1 {
        return KeychainDataV1(
            version: version,
            name: name,
            walletTypeRaw: walletTypeRaw,
            seed: seed,
            networkRaw: networkRaw,
            derivationTypeRaw: derivationTypeRaw,
            derivationPath: derivationPath,
            seedTypeRaw: seedTypeRaw,
            blockHeight: blockHeight,
            passphrase: passphrase
        )
    }
}


private struct UnsupportedKeychainDataWrapper: Codable {
    let name: String
    let walletTypeRaw: Int64
    let version: Int64

    var accountId: String {
        return "\(name)_\(walletTypeRaw)"
    }

    var isUnsupported: Bool {
        return version > 1
    }

    init(from pigeonData: UnsupportedKeychainData) {
        self.name = pigeonData.name
        self.walletTypeRaw = pigeonData.walletTypeRaw
        self.version = pigeonData.version
    }

    func toPigeonData() -> UnsupportedKeychainData {
        return UnsupportedKeychainData(
            version: version,
            name: name,
            walletTypeRaw: walletTypeRaw
        )
    }
}

public class CwKeychainPlugin: NSObject, FlutterPlugin, KeychainPlatformApi {
    private static let serviceName = "cw_keychain"

    public static func register(with registrar: FlutterPluginRegistrar) {
        #if os(iOS)
        let messenger = registrar.messenger()
        #elseif os(macOS)
        let messenger = registrar.messenger
        #endif

        let instance = CwKeychainPlugin()
        KeychainPlatformApiSetup.setUp(binaryMessenger: messenger, api: instance)
    }


    func available() -> Bool {
        // https://developer.apple.com/documentation/foundation/filemanager/ubiquityidentitytoken
        // de facto this is a check if user is signed into icloud
        return FileManager.default.ubiquityIdentityToken != nil
    }


    func put(item: KeychainDataV1, completion: @escaping (Result<String, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.print_with_prefix("put")
            let wrapper = KeychainDataWrapper(from: item)

            do {
                let walletData = try JSONEncoder().encode(wrapper)

                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.serviceName,
                    kSecAttrAccount as String: wrapper.accountId,
                    kSecAttrSynchronizable as String: true
                ]

                SecItemDelete(deleteQuery as CFDictionary)

                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.serviceName,
                    kSecAttrAccount as String: wrapper.accountId,
                    kSecValueData as String: walletData,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
                    kSecAttrSynchronizable as String: true
                ]

                let status = SecItemAdd(addQuery as CFDictionary, nil)

                if status != errSecSuccess {
                    completion(.failure(self.os_error(code: status, method: "put")))
                    return
                }

                self.print_with_prefix("put ok: \(wrapper.accountId)")
                completion(.success(wrapper.accountId))

            } catch {
                completion(.failure(error))
            }
        }
    }

    func get(id: String, completion: @escaping (Result<KeychainDataV1?, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.print_with_prefix("get")
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Self.serviceName,
                kSecAttrAccount as String: id,
                kSecReturnData as String: true,
                kSecMatchLimit as String: kSecMatchLimitOne,
                kSecAttrSynchronizable as String: true
            ]

            var item: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &item)

            if status == errSecItemNotFound {
                self.print_with_prefix("not found: \(id)")
                completion(.success(nil))
                return
            }

            if status != errSecSuccess {
                completion(.failure(self.os_error(code: status, method: "get")))
                return
            }

            guard let data = item as? Data else {
                completion(.failure(PigeonError(code: "no_data", message: "Keychain item did not contain data", details: nil)))
                return
            }

            do {
                let wrapper = try JSONDecoder().decode(KeychainDataWrapper.self, from: data)
                self.print_with_prefix("get ok: \(wrapper.accountId)")
                completion(.success(wrapper.toPigeonData()))
            } catch {
                completion(.failure(PigeonError(code: "decode_error", message: "decode fail: \(error)", details: nil)))
            }
        }
    }

    func delete(id: String, completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.print_with_prefix("delete")
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Self.serviceName,
                kSecAttrAccount as String: id,
                kSecAttrSynchronizable as String: true
            ]

            let status = SecItemDelete(query as CFDictionary)

            if status != errSecSuccess && status != errSecItemNotFound {
                completion(.failure(self.os_error(code: status, method: "delete")))
                return
            }

            self.print_with_prefix("delete ok: \(id)")
            completion(.success(()))
        }
    }

    func getAll(completion: @escaping (Result<[KeychainDataV1], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.print_with_prefix("getAll")
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Self.serviceName,
                kSecReturnData as String: true,
                kSecReturnAttributes as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll,
                kSecAttrSynchronizable as String: true
            ]

            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecItemNotFound {
                self.print_with_prefix("returning empty list because no items found")
                completion(.success([]))
                return
            }

            if status != errSecSuccess {
                completion(.failure(self.os_error(code: status, method: "getAll")))
                return
            }

            guard let itemsArray = result as? [[String: Any]] else {
                completion(.failure(PigeonError(code: "invalid_format", message: "invalid format", details: nil)))
                return
            }

            var results: [KeychainDataV1] = []
            let decoder = JSONDecoder()

            for dict in itemsArray {
                if let data = dict[kSecValueData as String] as? Data {
                    do {
                        let wrapper = try decoder.decode(KeychainDataWrapper.self, from: data)
                        self.print_with_prefix("decoded ok: \(wrapper.accountId)")
                        results.append(wrapper.toPigeonData())
                    } catch {
                        self.print_with_prefix("skip decoding item: \(error)\n\(data)")
                    }
                }
            }

            completion(.success(results))
        }
    }

    func getUnsupported(completion: @escaping (Result<[UnsupportedKeychainData], Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.print_with_prefix("getUnsupported")
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: Self.serviceName,
                kSecReturnData as String: true,
                kSecReturnAttributes as String: true,
                kSecMatchLimit as String: kSecMatchLimitAll,
                kSecAttrSynchronizable as String: true
            ]

            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)

            if status == errSecItemNotFound {
                self.print_with_prefix("returning empty list because no items found")
                completion(.success([]))
                return
            }

            if status != errSecSuccess {
                completion(.failure(self.os_error(code: status, method: "getAll")))
                return
            }

            guard let itemsArray = result as? [[String: Any]] else {
                completion(.failure(PigeonError(code: "invalid_format", message: "invalid format", details: nil)))
                return
            }

            var results: [UnsupportedKeychainData] = []
            let decoder = JSONDecoder()

            for dict in itemsArray {
                if let data = dict[kSecValueData as String] as? Data {
                    do {
                        let wrapper = try decoder.decode(UnsupportedKeychainDataWrapper.self, from: data)

                        guard wrapper.isUnsupported else {
                            self.print_with_prefix("skip supported item: \(wrapper.accountId) (version \(wrapper.version))")
                            continue
                        }

                        self.print_with_prefix("unsupported decoded ok: \(wrapper.accountId) (version \(wrapper.version))")
                        results.append(wrapper.toPigeonData())
                    } catch {
                        self.print_with_prefix("skip decoding item: \(error)\n\(data)")
                    }
                }
            }

            completion(.success(results))
        }
    }

    func putFakeUnsupported(completion: @escaping (Result<Void, Error>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            self.print_with_prefix("put")
            let wrapper = UnsupportedKeychainDataWrapper(from: UnsupportedKeychainData(
                version: 999,
                    name: "chuj",
                walletTypeRaw: 2
            ))

            do {
                let walletData = try JSONEncoder().encode(wrapper)

                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.serviceName,
                    kSecAttrAccount as String: wrapper.accountId,
                    kSecAttrSynchronizable as String: true
                ]

                SecItemDelete(deleteQuery as CFDictionary)

                let addQuery: [String: Any] = [
                    kSecClass as String: kSecClassGenericPassword,
                    kSecAttrService as String: Self.serviceName,
                    kSecAttrAccount as String: wrapper.accountId,
                    kSecValueData as String: walletData,
                    kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlocked,
                    kSecAttrSynchronizable as String: true
                ]

                let status = SecItemAdd(addQuery as CFDictionary, nil)

                if status != errSecSuccess {
                    completion(.failure(self.os_error(code: status, method: "put")))
                    return
                }

                self.print_with_prefix("putFakeUnsupported ok")
                completion(.success(()))

            } catch {
                completion(.failure(error))
            }
        }
    }



    private func os_error(code: OSStatus, method: String) -> PigeonError {
        PigeonError(
            code: "\(code)",
            message: "\(method) returned error \(code)",
            details: nil
        )
    }

    private func print_with_prefix(_ message: String) {
        NSLog("[\(Self.serviceName)] \(message)")
    }

}
