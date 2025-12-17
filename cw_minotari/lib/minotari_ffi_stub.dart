/// Stubbed FFI interface for Minotari wallet (temporary until Rust implementation is complete)
/// This allows the app to build and show Minotari in the UI without actual wallet functionality
class MinotariFfiStub {
  final String dataPath;
  bool _isInitialized = false;

  MinotariFfiStub({required this.dataPath});

  /// Create a new wallet from mnemonic (stubbed)
  Future<void> createFromMnemonic(String mnemonic, {String passphrase = ''}) async {
    // Simulate wallet creation delay
    await Future.delayed(Duration(milliseconds: 100));
    _isInitialized = true;
    throw UnimplementedError(
      'Minotari wallet creation is not yet implemented.\n\n'
      'The Minotari integration is currently in development. '
      'Wallet functionality will be available once the Rust FFI layer is completed.'
    );
  }

  /// Restore wallet from mnemonic (stubbed)
  Future<void> restore(String mnemonic, {String passphrase = ''}) async {
    await Future.delayed(Duration(milliseconds: 100));
    _isInitialized = true;
    throw UnimplementedError(
      'Minotari wallet restoration is not yet implemented.\n\n'
      'The Minotari integration is currently in development. '
      'Wallet functionality will be available once the Rust FFI layer is completed.'
    );
  }

  /// Get wallet address (stubbed)
  Future<String> getAddress() async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }
    // Return a placeholder address
    return 'xtm_placeholder_address_not_implemented';
  }

  /// Get wallet balance (stubbed)
  Future<Map<String, int>> getBalance() async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }
    // Return zero balance
    return {
      'available': 0,
      'pendingIncoming': 0,
      'pendingOutgoing': 0,
    };
  }

  /// Sync wallet with base node (stubbed)
  Future<void> sync(String baseNodeAddress) async {
    if (!_isInitialized) {
      throw Exception('Wallet not initialized');
    }
    // Simulate sync delay
    await Future.delayed(Duration(milliseconds: 200));
  }

  /// Get mnemonic (stubbed)
  String? getMnemonic() {
    return null;
  }

  /// Dispose of the wallet handle (stubbed)
  void dispose() {
    _isInitialized = false;
  }
}
