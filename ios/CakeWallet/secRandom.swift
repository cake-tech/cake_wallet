import Foundation

func secRandom(count: Int) -> Data? {
    var bytes = [Int8](repeating: 0, count: count)
    let status = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)

    if status == errSecSuccess {
        return Data(bytes: bytes, count: bytes.count)
    }
    
    return nil
}
