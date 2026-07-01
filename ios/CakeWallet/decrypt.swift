import Foundation
import CryptoSwift

func decrypt(data: Data, key: String, salt: String) -> String? {
    let keyBytes = key.data(using: .utf8)?.bytes ?? []
    let saltBytes = salt.data(using: .utf8)?.bytes ?? []
    
    guard let PBKDF2key = try? PKCS5.PBKDF2(password: keyBytes, salt:  saltBytes, iterations: 4096, variant: .sha256).calculate(),
          let cipher = try? Blowfish(key: PBKDF2key, padding: .pkcs7),
          let decryptedBytes = try? cipher.decrypt(data.bytes) else {
        return nil
    }
    
    let decryptedData = Data(decryptedBytes)
    return String(data: decryptedData, encoding: .utf8)
}
