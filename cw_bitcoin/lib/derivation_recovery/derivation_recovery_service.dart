import "package:bitcoin_base/bitcoin_base.dart";
import "package:blockchain_utils/blockchain_utils.dart";
import "package:collection/collection.dart";
import "package:cw_bitcoin/derivation_recovery/recovery_derivations.dart";
import "package:cw_bitcoin/derivation_recovery/recovery_scanner.dart";
import "package:cw_bitcoin/electrum_wallet.dart";
import "package:cw_bitcoin/exceptions.dart";
import "package:cw_bitcoin/pending_bitcoin_transaction.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/unspent_coin_type.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_type.dart";

/// A coin the recovery can move into the wallet.
class RecoveredCoin {
  RecoveredCoin({
    required this.hash,
    required this.vout,
    required this.value,
    required this.address,
    required this.type,
    required this.chain,
    required this.index,
    required this.isWalletCoin,
    required this.privateKey,
  });

  final String hash;
  final int vout;
  final int value;
  final String address;
  final BitcoinAddressType type;
  final RecoveryChain chain;
  final int index;

  /// One of the wallet's own coins that it signs with a key that doesn't match the address,
  /// rather than a coin on a path the wallet doesn't use at all.
  final bool isWalletCoin;

  final ECPrivate privateKey;
}

/// One of the wallet's own coins that it can't sign for, and whose key the search didn't find.
class UnrecoverableCoin {
  UnrecoverableCoin({
    required this.hash,
    required this.vout,
    required this.value,
    required this.address,
  });

  final String hash;
  final int vout;
  final int value;
  final String address;
}

class DerivationRecoveryResult {
  DerivationRecoveryResult({
    required this.coins,
    required this.unrecoverableCoins,
    required this.checkedAddresses,
  });

  final List<RecoveredCoin> coins;
  final List<UnrecoverableCoin> unrecoverableCoins;
  final int checkedAddresses;

  int get total => coins.fold(0, (sum, coin) => sum + coin.value);

  int get unrecoverableTotal => unrecoverableCoins.fold(0, (sum, coin) => sum + coin.value);
}

/// Finds funds the wallet can't reach — on derivation paths it doesn't use, or on its own
/// addresses with a key it derives wrongly — and sweeps them into one of its own addresses.
///
/// Runs only when the user asks for it, through the wallet's public API: the wallet itself never
/// derives, scans or stores any of these addresses.
class DerivationRecoveryService {
  DerivationRecoveryService(
    this.wallet, {
    RecoveryChainSource? source,
    this.depth = 200,
    this.gap = 20,
    this.keySearchDepth = 1000,
  }) : source = source ??
            ElectrumRecoveryChainSource(
              wallet.electrumClient,
              useBatch: wallet.shouldUseBatchFetching,
            );

  final ElectrumWallet wallet;
  final RecoveryChainSource source;

  /// Addresses checked on every chain before extending past used ones.
  final int depth;
  final int gap;

  /// How far the search for the key of a wallet coin goes on every chain.
  final int keySearchDepth;

  /// Bitcoin and Litecoin wallets with a seed on this device.
  static bool isSupported(ElectrumWallet wallet) =>
      (wallet.type == WalletType.bitcoin || wallet.type == WalletType.litecoin) &&
      !wallet.isHardwareWallet &&
      (wallet.seed?.isNotEmpty ?? false);

  /// Scans the recovery chains and checks the wallet's own coins, which should be up to date
  /// (refresh them with `updateAllUnspents` first).
  Future<DerivationRecoveryResult> scan({void Function(int checkedAddresses)? onProgress}) async {
    if (!isSupported(wallet)) {
      throw UnsupportedError("Derivation recovery needs a Bitcoin or Litecoin seed wallet");
    }

    final network = wallet.network;
    final masters =
        await RecoveryMasters.fromMnemonic(wallet.seed!, passphrase: wallet.passphrase ?? "");
    final chains = recoveryChains(
      nativeCoinType: _nativeCoinType,
      supportsTaproot: wallet.type == WalletType.bitcoin,
    );

    var checkedAddresses = 0;
    final used = await RecoveryScanner(
      masters: masters,
      chains: chains,
      network: network,
      source: source,
      depth: depth,
      gap: gap,
      onProgress: (checked) {
        checkedAddresses = checked;
        onProgress?.call(checked);
      },
    ).usedAddresses();
    final unspents = await source.unspents([for (final address in used) address.scriptHash]);

    final own = await _ownCoins();
    final coins = <String, RecoveredCoin>{};

    for (final address in used) {
      final hd = address.chain.hd(masters);
      for (final unspent in unspents[address.scriptHash] ?? const <RecoveryUnspent>[]) {
        final outpoint = _outpoint(unspent.hash, unspent.vout);
        final isWalletCoin = own.outpoints.contains(outpoint);
        // The wallet spends its own coins itself, unless it signs them with the wrong key.
        if (isWalletCoin && !own.misKeyed.containsKey(outpoint)) {
          continue;
        }

        coins[outpoint] = RecoveredCoin(
          hash: unspent.hash,
          vout: unspent.vout,
          value: unspent.value,
          address: address.address,
          type: address.type,
          chain: address.chain,
          index: address.index,
          isWalletCoin: isWalletCoin,
          privateKey: ECPrivate(hd.childKey(Bip32KeyIndex(address.index)).privateKey),
        );
      }
    }

    // Wallet coins on addresses past what the scan covers: search for their keys.
    final unrecoverable = <UnrecoverableCoin>[];
    for (final entry in own.misKeyed.entries) {
      if (coins.containsKey(entry.key)) {
        continue;
      }

      final utxo = entry.value;
      final address = utxo.ownerDetails.address.toAddress(network);
      final key = await searchRecoveryKey(
        masters: masters,
        chains: chains,
        address: address,
        type: utxo.utxo.scriptType,
        network: network,
        maxIndex: keySearchDepth,
      );

      if (key == null) {
        unrecoverable.add(
          UnrecoverableCoin(
            hash: utxo.utxo.txHash,
            vout: utxo.utxo.vout,
            value: utxo.utxo.value.toInt(),
            address: address,
          ),
        );
        continue;
      }

      coins[entry.key] = RecoveredCoin(
        hash: utxo.utxo.txHash,
        vout: utxo.utxo.vout,
        value: utxo.utxo.value.toInt(),
        address: address,
        type: utxo.utxo.scriptType,
        chain: key.chain,
        index: key.index,
        isWalletCoin: true,
        privateKey: key.privateKey,
      );
    }

    return DerivationRecoveryResult(
      coins: coins.values.toList(),
      unrecoverableCoins: unrecoverable,
      checkedAddresses: checkedAddresses,
    );
  }

  /// One transaction moving all of [result]'s coins to an unused receive address of the wallet.
  Future<PendingBitcoinTransaction> createSweepTransaction(
    DerivationRecoveryResult result, {
    required int feeRate,
  }) async {
    if (result.coins.isEmpty) {
      throw BitcoinTransactionNoInputsException();
    }

    final network = wallet.network;
    final destination = RegexUtils.addressTypeFromStr(_ownReceiveAddress(), network);
    final utxos = [
      for (final coin in result.coins)
        UtxoWithAddress(
          utxo: BitcoinUtxo(
            txHash: coin.hash,
            value: BigInt.from(coin.value),
            vout: coin.vout,
            scriptType: coin.type,
          ),
          ownerDetails: UtxoAddressDetails(
            publicKey: coin.privateKey.getPublic().toHex(),
            address: RegexUtils.addressTypeFromStr(coin.address, network),
          ),
        ),
    ];

    final total = result.total;
    final fee = await wallet.calcFee(
      utxos: utxos,
      outputs: <BitcoinOutput>[BitcoinOutput(address: destination, value: BigInt.from(total))],
      network: network,
      feeRate: feeRate,
      inputPrivKeyInfos: [
        for (final coin in result.coins)
          ECPrivateInfo(coin.privateKey, coin.type == SegwitAddresType.p2tr, tweak: true),
      ],
      vinOutpoints: [
        for (final coin in result.coins) Outpoint(txid: coin.hash, index: coin.vout),
      ],
    );

    final amount = total - fee;
    if (BigInt.from(amount) <= wallet.networkDustAmount) {
      throw BitcoinTransactionNoDustException();
    }

    final keys = {
      for (final coin in result.coins) coin.privateKey.getPublic().toHex(): coin.privateKey,
    };
    final transaction = BitcoinTransactionBuilder(
      utxos: utxos,
      outputs: <BitcoinOutput>[BitcoinOutput(address: destination, value: BigInt.from(amount))],
      fee: BigInt.from(fee),
      network: network,
      enableRBF: true,
    ).buildTransaction((digest, utxo, publicKey, sighash) {
      final key = keys[publicKey]!;
      return utxo.utxo.isP2tr()
          ? key.signTapRoot(digest, sighash: sighash, tweak: true)
          : key.signInput(digest, sigHash: sighash);
    });

    return PendingBitcoinTransaction(
      transaction,
      wallet.type,
      accountIndex: wallet.currentAccountIndex,
      electrumClient: wallet.electrumClient,
      amount: Money.fromInt(amount, wallet.currency),
      fee: Money.fromInt(fee, wallet.currency),
      feeRate: feeRate.toString(),
      network: network,
      hasChange: false,
      isSendAll: true,
      hasTaprootInputs: utxos.any((utxo) => utxo.utxo.isP2tr()),
      utxos: utxos,
      isViewOnly: false,
    )..addListener((_) async {
        await wallet.updateAllUnspents();
        await wallet.updateBalance();
      });
  }

  int get _nativeCoinType {
    if (!wallet.network.isMainnet) {
      return 1;
    }
    return wallet.type == WalletType.litecoin ? 2 : 0;
  }

  /// The wallet's own coins, and those of them it signs with a key that doesn't match their
  /// address — as the wallet itself would sign them, asked through a send-all estimate.
  Future<_OwnCoins> _ownCoins() async {
    final outpoints = {for (final coin in wallet.unspentCoins) _outpoint(coin.hash, coin.vout)};
    final misKeyed = <String, UtxoWithAddress>{};

    try {
      final estimate = await wallet.estimateSendAllTx(
        [
          BitcoinOutput(
            address: RegexUtils.addressTypeFromStr(_ownReceiveAddress(), wallet.network),
            value: BigInt.zero,
          ),
        ],
        1,
        coinTypeToSpendFrom: UnspentCoinType.nonMweb,
      );

      for (final utxo in estimate.utxos) {
        // Silent payment outputs are keyed by their tweak, not a derivation path.
        if (utxo.utxo.isSilentPayment == true) {
          continue;
        }

        final address = utxo.ownerDetails.address.toAddress(wallet.network);
        if (addressForPublicKey(utxo.public(), utxo.utxo.scriptType, wallet.network) != address) {
          misKeyed[_outpoint(utxo.utxo.txHash, utxo.utxo.vout)] = utxo;
        }
      }
    } catch (e) {
      // No spendable coins, or too few to cover a fee: there's nothing of the wallet's to check.
      printV("Derivation recovery: couldn't check the wallet's own keys: $e");
    }

    return _OwnCoins(outpoints, misKeyed);
  }

  /// An unused P2WPKH receive address of the wallet's own, on its current account.
  String _ownReceiveAddress() {
    final account = wallet.type == WalletType.bitcoin ? wallet.currentAccountIndex : 0;
    final receive = wallet.walletAddresses.allAddresses
        .where(
          (address) =>
              address.type == SegwitAddresType.p2wpkh &&
              !address.isHidden &&
              address.accountIndex == account,
        )
        .toList();
    return (receive.firstWhereOrNull((address) => !address.isUsed) ?? receive.first).address;
  }

  static String _outpoint(String hash, int vout) => "$hash:$vout";
}

class _OwnCoins {
  _OwnCoins(this.outpoints, this.misKeyed);

  final Set<String> outpoints;
  final Map<String, UtxoWithAddress> misKeyed;
}
