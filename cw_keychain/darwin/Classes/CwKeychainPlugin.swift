#if os(iOS)
import Flutter
#elseif os(macOS)
import FlutterMacOS
#endif


private struct KeychainDataWrapper: Codable {
    let name: String
    let walletTypeRaw: Int64
    let seed: String
    let seedTypeRaw: Int64?
    let blockHeight: Int64?
    let passphrase: String?

    var accountId: String {
        return "\(name)_\(walletTypeRaw)"
    }

    init(from pigeonData: KeychainData) {
        self.name = pigeonData.name
        self.walletTypeRaw = pigeonData.walletTypeRaw
        self.seed = pigeonData.seed
        self.seedTypeRaw = pigeonData.seedTypeRaw
        self.blockHeight = pigeonData.blockHeight
        self.passphrase = pigeonData.passphrase
    }

    func toPigeonData() -> KeychainData {
        return KeychainData(
            name: name,
            walletTypeRaw: walletTypeRaw,
            seed: seed,
            seedTypeRaw: seedTypeRaw,
            blockHeight: blockHeight,
            passphrase: passphrase
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


    func getAll() throws -> [KeychainData] {
        print_with_prefix("getAll")
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
            print_with_prefix("returning empty list because no items found")
            return []
        }

        if status != errSecSuccess {
            throw os_error(code: status, method: "getAll")
        }

        guard let itemsArray = result as? [[String: Any]] else {
            throw PigeonError(code: "invalid_format", message: "invalid format", details: nil)
        }

        var results: [KeychainData] = []

        for dict in itemsArray {
            if let data = dict[kSecValueData as String] as? Data {
                do {
                    let wrapper = try JSONDecoder().decode(KeychainDataWrapper.self, from: data)
                    print_with_prefix("decoded ok: \(wrapper.accountId)")
                    results.append(wrapper.toPigeonData())
                } catch {
                    print_with_prefix("fail decoding item: \(error)\n\(data)")
                }
            }
        }

        return results
    }

    func put(item: KeychainData) throws -> String {
        print_with_prefix("put")
        let wrapper = KeychainDataWrapper(from: item)
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
            throw os_error(code: status, method: "put")
        }

        print_with_prefix("put ok: \(wrapper.accountId)")
        return wrapper.accountId
    }

    func delete(id: String) throws {
        print_with_prefix("delete")
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: Self.serviceName,
            kSecAttrAccount as String: id,
            kSecAttrSynchronizable as String: true
        ]

        let status = SecItemDelete(query as CFDictionary)


        if status != errSecSuccess && status != errSecItemNotFound {
            throw os_error(code: status, method: "delete")
        }
        print_with_prefix("delete ok: \(id)")
    }

    func get(id: String) throws -> KeychainData {
        print_with_prefix("get")
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

        if status != errSecSuccess {
            throw os_error(code: status, method: "get")
        }

        guard let data = item as? Data else {
            throw PigeonError(code: "no_data", message: "id not found", details: nil)
        }

        do {
            let wrapper = try JSONDecoder().decode(KeychainDataWrapper.self, from: data)
            print_with_prefix("get ok: \(wrapper.accountId)")
            return wrapper.toPigeonData()
        } catch {
            throw PigeonError(code: "decode_error", message: "decode fail: \(error)", details: nil)
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
        print("[\(Self.serviceName)] \(message)")
    }

}
