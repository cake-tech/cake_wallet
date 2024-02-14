part of 'lightning.dart';

class CWLightning extends Lightning {
	@override
	TransactionPriority getMediumTransactionPriority() => BitcoinTransactionPriority.medium;	

	@override
	WalletCredentials createLightningRestoreWalletFromSeedCredentials({
    required String name,
    required String mnemonic,
    required String password})
		=> BitcoinRestoreWalletFromSeedCredentials(name: name, mnemonic: mnemonic, password: password);

	@override
	WalletCredentials createLightningRestoreWalletFromWIFCredentials({
    required String name,
    required String password,
    required String wif,
    WalletInfo? walletInfo})
		=> BitcoinRestoreWalletFromWIFCredentials(name: name, password: password, wif: wif, walletInfo: walletInfo);
	
	@override
	WalletCredentials createLightningNewWalletCredentials({
    required String name,
    WalletInfo? walletInfo})
		=> BitcoinNewWalletCredentials(name: name, walletInfo: walletInfo);

	@override
	List<String> getWordList() => wordlist;

	@override
	Map<String, String> getWalletKeys(Object wallet) {
		final lightningWallet = wallet as ElectrumWallet;
		final keys = lightningWallet.keys;
		
		return <String, String>{
			'wif': keys.wif,
			'privateKey': keys.privateKey,
			'publicKey': keys.publicKey	
		};
	}
	
	@override
	List<TransactionPriority> getTransactionPriorities() 
		=> BitcoinTransactionPriority.all;

	@override
	TransactionPriority deserializeLightningTransactionPriority(int raw)
		=> BitcoinTransactionPriority.deserialize(raw: raw);

	@override
	int getFeeRate(Object wallet, TransactionPriority priority) {
		final lightningWallet = wallet as ElectrumWallet;
		return lightningWallet.feeRate(priority);
	}

	@override
	Future<void> generateNewAddress(Object wallet, String label) async {
		final lightningWallet = wallet as ElectrumWallet;
		await lightningWallet.walletAddresses.generateNewAddress(label: label);
		await wallet.save();
	}

	@override
	Future<void> updateAddress(Object wallet,String address, String label) async {
		final lightningWallet = wallet as ElectrumWallet;
		lightningWallet.walletAddresses.updateAddress(address, label);
		await wallet.save();
	}
	
	@override
	Object createLightningTransactionCredentials(List<Output> outputs, {required TransactionPriority priority, int? feeRate})
		=> BitcoinTransactionCredentials(
			outputs.map((out) => OutputInfo(
					fiatAmount: out.fiatAmount,
					cryptoAmount: out.cryptoAmount,
					address: out.address,
					note: out.note,
					sendAll: out.sendAll,
					extractedAddress: out.extractedAddress,
					isParsedAddress: out.isParsedAddress,
					formattedCryptoAmount: out.formattedCryptoAmount))
			.toList(),
			priority: priority as BitcoinTransactionPriority,
			feeRate: feeRate);

	@override
	Object createLightningTransactionCredentialsRaw(List<OutputInfo> outputs, {TransactionPriority? priority, required int feeRate})
		=> BitcoinTransactionCredentials(
				outputs,
				priority: priority != null ? priority as BitcoinTransactionPriority : null,
				feeRate: feeRate);

	@override
	List<String> getAddresses(Object wallet) {
		final lightningWallet = wallet as ElectrumWallet;
		return lightningWallet.walletAddresses.addresses
			.map((BitcoinAddressRecord addr) => addr.address)
			.toList();
	}

	@override
	@computed
	List<ElectrumSubAddress> getSubAddresses(Object wallet) {
		final electrumWallet = wallet as ElectrumWallet;
		return electrumWallet.walletAddresses.addresses
			.map((BitcoinAddressRecord addr) => ElectrumSubAddress(
				id: addr.index,
				name: addr.name,
				address: addr.address,
				txCount: addr.txCount,
				balance: addr.balance,
				isChange: addr.isHidden))
			.toList();
	}

	@override
	String getAddress(Object wallet) {
		final lightningWallet = wallet as ElectrumWallet;
		return lightningWallet.walletAddresses.address;
	}

	@override
	String formatterLightningAmountToString({required int amount})
		=> bitcoinAmountToString(amount: amount);

	@override	
	double formatterLightningAmountToDouble({required int amount})
		=> bitcoinAmountToDouble(amount: amount);

	@override	
	int formatterStringDoubleToLightningAmount(String amount)
		=> stringDoubleToBitcoinAmount(amount);

  @override
  String lightningTransactionPriorityWithLabel(TransactionPriority priority, int rate)
    => (priority as BitcoinTransactionPriority).labelWithRate(rate);

	@override
	List<BitcoinUnspent> getUnspents(Object wallet) {
		final lightningWallet = wallet as ElectrumWallet;
		return lightningWallet.unspentCoins;
	}

	Future<void> updateUnspents(Object wallet) async {
		final lightningWallet = wallet as ElectrumWallet;
		await lightningWallet.updateUnspent();
	}

	WalletService createLightningWalletService(Box<WalletInfo> walletInfoSource, Box<UnspentCoinsInfo> unspentCoinSource) {
		return LightningWalletService(walletInfoSource, unspentCoinSource);
	}
  
  @override
  TransactionPriority getLightningTransactionPriorityMedium()
    => BitcoinTransactionPriority.medium;

  @override
  TransactionPriority getLightningTransactionPrioritySlow()
    => BitcoinTransactionPriority.slow;
}