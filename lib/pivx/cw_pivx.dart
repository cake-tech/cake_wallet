part of 'pivx.dart';

class CWPivx extends Pivx {
  @override
  WalletService createPivxWalletService(
      Box<UnspentCoinsInfo> unspentCoinSource, bool isDirect) {
    return PivxWalletService(unspentCoinSource, isDirect);
  }

  @override
  WalletCredentials createPivxNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
    String? password,
    String? passphrase,
    String? mnemonic,
  }) =>
      PivxNewWalletCredentials(
        name: name,
        walletInfo: walletInfo,
        password: password,
        passphrase: passphrase,
        mnemonic: mnemonic,
      );

  @override
  WalletCredentials createPivxRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password,
    String? passphrase,
    int? height,
  }) =>
      PivxRestoreWalletFromSeedCredentials(
        name: name,
        mnemonic: mnemonic,
        password: password,
        passphrase: passphrase,
        height: height,
      );

  @override
  TransactionPriority deserializePivxTransactionPriority(int raw) =>
      PivxTransactionPriority.deserialize(raw: raw);

  @override
  TransactionPriority getDefaultTransactionPriority() =>
      PivxTransactionPriority.medium;

  @override
  List<TransactionPriority> getTransactionPriorities() =>
      PivxTransactionPriority.all;

  @override
  TransactionPriority getPivxTransactionPrioritySlow() =>
      PivxTransactionPriority.slow;

  @override
  int getHeightByDate({required DateTime date}) {
    // pivx has ~60s blocks. anchor to an observed (height, date) and walk back
    // at ~1440 blocks/day. underestimating is safe (scans a little extra);
    // overestimating skips notes, so subtract a one-day margin and never return
    // above the anchor.
    const anchorHeight = 5552910; // observed db_height ~2026-08-23
    final anchorDate = DateTime.utc(2026, 8, 23);
    const blocksPerDay = 1440;
    // SaplingConstants.mainnetSaplingActivationHeight (not exported to app layer)
    const activationFloor = 2700500;

    final daysBefore = anchorDate.difference(date).inDays;
    final estimated = anchorHeight - (daysBefore + 1) * blocksPerDay;
    if (estimated < activationFloor) return activationFloor;
    if (estimated > anchorHeight) return anchorHeight;
    return estimated;
  }

  @override
  ReceivePageOption getSelectedAddressType(Object wallet) {
    final pivxWallet = wallet as PivxWallet;
    final addresses = pivxWallet.walletAddresses as PivxWalletAddresses;
    return addresses.selectedShieldedAddress != null
        ? PivxReceivePageOption.shieldedSapling
        : PivxReceivePageOption.transparent;
  }

  @override
  bool isPivxReceivePageOption(ReceivePageOption option) =>
      option is PivxReceivePageOption;

  @override
  dynamic getOptionToType(ReceivePageOption option) =>
      (option as PivxReceivePageOption).toType();

  @override
  Future<void> setAddressType(Object wallet, dynamic option) async {
    final pivxWallet = wallet as PivxWallet;
    final addresses = pivxWallet.walletAddresses as PivxWalletAddresses;
    if (option == PivxAddressType.shieldedSapling) {
      final shielded = pivxWallet.currentShieldedAddress;
      if (shielded != null && shielded.isNotEmpty) {
        addresses.address = shielded;
      }
    } else {
      addresses.clearShieldedSelection();
    }
  }

  @override
  Future<int> estimatedSendFee(Object wallet, TransactionPriority priority, int amount,
          {required String toAddress,
          required UnspentCoinType source,
          bool sendAll = false}) =>
      (wallet as PivxWallet).estimatedSendFee(priority, amount,
          toAddress: toAddress, source: source, sendAll: sendAll);

  @override
  Future<int> spendableAmount(Object wallet, UnspentCoinType source, String toAddress) =>
      (wallet as PivxWallet).spendableAmount(toAddress: toAddress, source: source);
}
