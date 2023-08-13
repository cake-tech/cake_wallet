part of 'bitcoin_cash.dart';

class CWBitcoinCash extends BitcoinCash {
  @override
  String getMnemonic(int? strength) => Mnemonic.generate();

  @override
  Uint8List getSeedFromMnemonic(String seed) => Mnemonic.toSeed(seed);

  @override
  WalletService createBitcoinCashWalletService(
      Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
    return BitcoinCashWalletService(walletInfoSource, unspentCoinSource);
  }

  @override
  WalletCredentials createBitcoinCashNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo,
  }) =>
      BitcoinCashNewWalletCredentials(name: name, walletInfo: walletInfo);

// 	@override
// 	TransactionPriority getMediumTransactionPriority() => BitcoinTransactionPriority.medium;
//
// 	@override
// 	WalletCredentials createBitcoinRestoreWalletFromSeedCredentials({
//     required String name,
//     required String mnemonic,
//     required String password})
// 		=> BitcoinRestoreWalletFromSeedCredentials(name: name, mnemonic: mnemonic, password: password);
//
// 	@override
// 	WalletCredentials createBitcoinRestoreWalletFromWIFCredentials({
//     required String name,
//     required String password,
//     required String wif,
//     WalletInfo? walletInfo})
// 		=> BitcoinRestoreWalletFromWIFCredentials(name: name, password: password, wif: wif, walletInfo: walletInfo);
//
// 	@override
// 	WalletCredentials createBitcoinNewWalletCredentials({
//     required String name,
//     WalletInfo? walletInfo})
// 		=> BitcoinNewWalletCredentials(name: name, walletInfo: walletInfo);
//
//
// 	@override
// 	Map<String, String> getWalletKeys(Object wallet) {
// 		final bitcoinWallet = wallet as ElectrumWallet;
// 		final keys = bitcoinWallet.keys;
//
// 		return <String, String>{
// 			'wif': keys.wif,
// 			'privateKey': keys.privateKey,
// 			'publicKey': keys.publicKey
// 		};
// 	}
//
// 	@override
// 	List<TransactionPriority> getTransactionPriorities()
// 		=> BitcoinTransactionPriority.all;
//
// 	List<TransactionPriority> getLitecoinTransactionPriorities()
// 		=> LitecoinTransactionPriority.all;
//
// 	@override
// 	TransactionPriority deserializeBitcoinTransactionPriority(int raw)
// 		=> BitcoinTransactionPriority.deserialize(raw: raw);
//
// 	@override
// 	TransactionPriority deserializeLitecoinTransactionPriority(int raw)
// 		=> LitecoinTransactionPriority.deserialize(raw: raw);
//
// 	@override
// 	int getFeeRate(Object wallet, TransactionPriority priority) {
// 		final bitcoinWallet = wallet as ElectrumWallet;
// 		return bitcoinWallet.feeRate(priority);
// 	}
//
// 	@override
// 	Future<void> generateNewAddress(Object wallet) async {
// 		final bitcoinWallet = wallet as ElectrumWallet;
// 		await bitcoinWallet.walletAddresses.generateNewAddress();
// 	}
//
// 	@override
// 	Object createBitcoinTransactionCredentials(List<Output> outputs, {required TransactionPriority priority, int? feeRate})
// 		=> BitcoinTransactionCredentials(
// 			outputs.map((out) => OutputInfo(
// 					fiatAmount: out.fiatAmount,
// 					cryptoAmount: out.cryptoAmount,
// 					address: out.address,
// 					note: out.note,
// 					sendAll: out.sendAll,
// 					extractedAddress: out.extractedAddress,
// 					isParsedAddress: out.isParsedAddress,
// 					formattedCryptoAmount: out.formattedCryptoAmount))
// 			.toList(),
// 			priority: priority as BitcoinTransactionPriority,
// 			feeRate: feeRate);
//
// 	@override
// 	Object createBitcoinTransactionCredentialsRaw(List<OutputInfo> outputs, {TransactionPriority? priority, required int feeRate})
// 		=> BitcoinTransactionCredentials(
// 				outputs,
// 				priority: priority != null ? priority as BitcoinTransactionPriority : null,
// 				feeRate: feeRate);
//
// 	@override
// 	List<String> getAddresses(Object wallet) {
// 		final bitcoinWallet = wallet as ElectrumWallet;
// 		return bitcoinWallet.walletAddresses.addresses
// 			.map((BitcoinAddressRecord addr) => addr.address)
// 			.toList();
// 	}
//
// 	@override
// 	String getAddress(Object wallet) {
// 		final bitcoinWallet = wallet as ElectrumWallet;
// 		return bitcoinWallet.walletAddresses.address;
// 	}
//
// 	@override
// 	String formatterBitcoinAmountToString({required int amount})
// 		=> bitcoinAmountToString(amount: amount);
//
// 	@override
// 	double formatterBitcoinAmountToDouble({required int amount})
// 		=> bitcoinAmountToDouble(amount: amount);
//
// 	@override
// 	int formatterStringDoubleToBitcoinAmount(String amount)
// 		=> stringDoubleToBitcoinAmount(amount);
//
//   @override
//   String bitcoinTransactionPriorityWithLabel(TransactionPriority priority, int rate)
//     => (priority as BitcoinTransactionPriority).labelWithRate(rate);
//
// 	void updateUnspents(Object wallet) async {
// 		final bitcoinWallet = wallet as ElectrumWallet;
// 		await bitcoinWallet.updateUnspent();
// 	}
//
// 	WalletService createBitcoinWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
// 		return BitcoinWalletService(walletInfoSource, unspentCoinSource);
// 	}
//
// 	WalletService createLitecoinWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
// 		return LitecoinWalletService(walletInfoSource, unspentCoinSource);
// 	}
//
//   @override
//   TransactionPriority getBitcoinTransactionPriorityMedium()
//     => BitcoinTransactionPriority.medium;
//
//   @override
//   TransactionPriority getLitecoinTransactionPriorityMedium()
//     => LitecoinTransactionPriority.medium;
//
//   @override
//   TransactionPriority getBitcoinTransactionPrioritySlow()
//     => BitcoinTransactionPriority.slow;
//
//   @override
//   TransactionPriority getLitecoinTransactionPrioritySlow()
//     => LitecoinTransactionPriority.slow;
}
