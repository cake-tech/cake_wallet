import AppIntents

@available(iOS 16.4, *)
struct CakeWalletShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ScanQRIntent(),
            phrases: [
                "Scan QR with \(.applicationName)",
                "Pay with \(.applicationName)",
                "Scan payment with \(.applicationName)"
            ],
            shortTitle: "Scan QR Code",
            systemImageName: "qrcode.viewfinder"
        )
    }
}
