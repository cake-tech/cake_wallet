part of "wallet_restore_cubit.dart";

class WalletRestoreState extends Equatable {
  WalletRestoreState({
    required this.mode,
    required this.isButtonEnabled,
    this.hasPassphrase = false,
    ExecutionState? executionState,
    this.walletPassword,
    this.repeatedWalletPassword,
    this.useTestnet = false,
    this.zcashNetwork = ZcashNetworkType.mainnet,
  }) : executionState = executionState ?? InitialExecutionState();

  final WalletRestoreMode mode;
  final bool isButtonEnabled;
  final bool hasPassphrase;
  final ExecutionState executionState;
  final String? walletPassword;
  final String? repeatedWalletPassword;
  final bool useTestnet;
  final int zcashNetwork;

  bool get passphraseAvailable => mode == WalletRestoreMode.seed;

  bool get isExecuting => executionState is IsExecutingState;

  WalletRestoreState copyWith({
    WalletRestoreMode? mode,
    bool? isButtonEnabled,
    bool? hasPassphrase,
    ExecutionState? executionState,
    String? Function()? walletPassword,
    String? Function()? repeatedWalletPassword,
    bool? useTestnet,
    int? zcashNetwork,
  }) =>
      WalletRestoreState(
        mode: mode ?? this.mode,
        isButtonEnabled: isButtonEnabled ?? this.isButtonEnabled,
        hasPassphrase: hasPassphrase ?? this.hasPassphrase,
        executionState: executionState ?? this.executionState,
        walletPassword: walletPassword != null ? walletPassword() : this.walletPassword,
        repeatedWalletPassword:
            repeatedWalletPassword != null ? repeatedWalletPassword() : this.repeatedWalletPassword,
        useTestnet: useTestnet ?? this.useTestnet,
        zcashNetwork: zcashNetwork ?? this.zcashNetwork,
      );

  @override
  List<Object?> get props => [
        mode,
        isButtonEnabled,
        hasPassphrase,
        executionState,
        walletPassword,
        repeatedWalletPassword,
        useTestnet,
        zcashNetwork,
      ];
}
