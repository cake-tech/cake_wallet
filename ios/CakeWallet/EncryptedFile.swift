import Foundation
import CryptoSwift

class EncryptedFile {
    
    private(set) var fileName: String
    private(set) var url: URL
    private let key: Array<UInt8>
    private let salt: Array<UInt8>
    
    init(url: URL, key: String, salt: String) {
        self.key = key.data(using: .utf8)?.bytes ?? []
        self.salt = salt.data(using: .utf8)?.bytes ?? []
        self.url = url
        self.fileName = url.lastPathComponent
    }
    
    func readRawContent() -> String? {
        guard let binaryContent = try? Data(contentsOf: url) else {
            return nil
        }
        
        return String(data: binaryContent, encoding: .utf8)
    }
    
    func decryptedContent() -> String? {
        guard
            let rawContent = readRawContent(),
            let decryptedBytes = try? cipherBuilder().decrypt(rawContent.bytes) else {
            return nil
        }
        
        let decryptedData = Data(decryptedBytes)
        return String(data: decryptedData, encoding: .utf8)
    }
    
    func cipherBuilder() -> Cipher {
        let PBKDF2key = try! PKCS5.PBKDF2(password: key, salt:  salt, iterations: 4096, variant: .sha256).calculate()
        return try! Blowfish(key: PBKDF2key, padding: .pkcs7)
    }
}

func readTradesList(key: String, salt: String) -> String? {
    let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathComponent("trades_list.json")

    return EncryptedFile(
        url: url,
        key: key,
        salt: salt).decryptedContent()
}
