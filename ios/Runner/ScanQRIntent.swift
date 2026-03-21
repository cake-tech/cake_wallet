import AppIntents
import UIKit

@available(iOS 16.0, *)
struct ScanQRIntent: AppIntent {
    static var title: LocalizedStringResource = "Scan QR Code"
    static var description = IntentDescription("Open Cake Wallet to scan a QR code for payment")
    static var openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult {
        await UIApplication.shared.open(URL(string: "cakewallet://quickaction/scan")!)
        return .result()
    }
}
