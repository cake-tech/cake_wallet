import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bip32/bip32.dart' as bip32;
import 'package:bip39/bip39.dart' as bip39;
import 'package:cw_core/cake_hive.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/node.dart';
import 'package:cw_core/parse_fixed.dart';
import 'package:cw_core/pathForWallet.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/sync_status.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/evm_chain_formatter.dart';
import 'package:cw_evm/evm_chain_transaction_credentials.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet_addresses.dart';
import 'package:cw_evm/hardware/evm_chain_bitbox_credentials.dart';
import 'package:cw_evm/hardware/evm_chain_ledger_credentials.dart';
import 'package:cw_evm/hardware/evm_chain_trezor_credentials.dart';
import 'package:hex/hex.dart';
import 'package:hive/hive.dart';
import 'package:mobx/mobx.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/web3dart.dart';
import 'package:eth_sig_util/eth_sig_util.dart';

import 'evm_chain_transaction_info.dart';
import 'evm_erc20_balance.dart';

part 'evm_chain_wallet.g.dart';

const Map<String, String> methodSignatureToType = {
  '0x095ea7b3': 'approval',
  '0xa9059cbb': 'transfer',
  '0x23b872dd': 'transferFrom',
  '0x574da717': 'transferOut',
  '0x2e1a7d4d': 'withdraw',
  '0x7ff36ab5': 'swapExactETHForTokens',
  '0x40c10f19': 'mint',
  '0x44bc937b': 'depositWithExpiry',
  '0xd0e30db0': 'deposit',
  '0xe8e33700': 'addLiquidity',
  '0xd505accf': 'permit',
};

abstract class EVMChainWallet = EVMChainWalletBase with _$EVMChainWallet;

abstract class EVMChainWalletBase
    extends WalletBase<EVMChainERC20Balance, EVMChainTransactionHistory, EVMChainTransactionInfo>
    with Store, WalletKeysFile {
  EVMChainWalletBase({
    required WalletInfo walletInfo,
    required EVMChainClient client,
    required CryptoCurrency nativeCurrency,
    String? mnemonic,
    String? privateKey,
    required String password,
    EVMChainERC20Balance? initialBalance,
    required this.encryptionFileUtils,
    this.passphrase,
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _isTransactionUpdating = false,
        _client = client,
        walletAddresses = EVMChainWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, EVMChainERC20Balance>.of(
          {
            // Not sure of this yet, will it work? will it not?
            nativeCurrency: initialBalance ?? EVMChainERC20Balance(BigInt.zero),
          },
        ),
        super(walletInfo) {
    this.walletInfo = walletInfo;
    transactionHistory = setUpTransactionHistory(walletInfo, password, encryptionFileUtils);

    if (!CakeHive.isAdapterRegistered(Erc20Token.typeId)) {
      CakeHive.registerAdapter(Erc20TokenAdapter());
    }

    sharedPrefs.complete(SharedPreferences.getInstance());
  }

  final String? _mnemonic;
  final String? _hexPrivateKey;
  final String _password;
  final EncryptionFileUtils encryptionFileUtils;

  late final Box<Erc20Token> erc20TokensBox;

  late final Box<Erc20Token> evmChainErc20TokensBox;

  late final Credentials _evmChainPrivateKey;

  Credentials get evmChainPrivateKey => _evmChainPrivateKey;

  late final EVMChainClient _client;

  int gasPrice = 0;
  int? gasBaseFee = 0;
  int estimatedGasUnits = 0;

  Timer? _updateFeesTimer;

  bool _isTransactionUpdating;

  // TODO: remove after integrating our own node and having eth_newPendingTransactionFilter
  Timer? _transactionsUpdateTimer;

  @override
  WalletAddresses walletAddresses;

  @override
  @observable
  SyncStatus syncStatus;

  @override
  @observable
  late ObservableMap<CryptoCurrency, EVMChainERC20Balance> balance;

  Completer<SharedPreferences> sharedPrefs = Completer();

  //! Methods to be overridden by every child

  void addInitialTokens([bool isMigration]);

  // Future<EVMChainWallet> open({
  //   required String name,
  //   required String password,
  //   required WalletInfo walletInfo,
  // });

  List<String> get getDefaultTokenContractAddresses;

  Future<void> initErc20TokensBox();

  String getTransactionHistoryFileName();

  Future<bool> checkIfScanProviderIsEnabled();

  EVMChainTransactionInfo getTransactionInfo(
      EVMChainTransactionModel transactionModel, String address);

  Erc20Token createNewErc20TokenObject(Erc20Token token, String? iconPath);

  EVMChainTransactionHistory setUpTransactionHistory(
    WalletInfo walletInfo,
    String password,
    EncryptionFileUtils encryptionFileUtils,
  );

  @override
  Future<bool> checkNodeHealth() async {
    try {
      // Check native balance
      await _client.getBalance(_evmChainPrivateKey.address, throwOnError: true);

      // Check USDC token balance
      String usdcContractAddress;

      switch (_client.chainId) {
        case 1:
          usdcContractAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
          break;
        case 137:
          usdcContractAddress = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174";
          break;
        case 8453:
          usdcContractAddress = "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913";
          break;
        default:
          return true;
      }

      await _client.fetchERC20Balances(
        _evmChainPrivateKey.address,
        usdcContractAddress,
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  //! Common Methods across child classes

  String idFor(String name, WalletType type) => '${walletTypeToString(type).toLowerCase()}_$name';

  Future<void> init() async {
    await initErc20TokensBox();

    await walletAddresses.init();
    await transactionHistory.init();

    // check for Already existing scam tokens, cuz users can get scammed twice ¯\_(ツ)_/¯
    await _checkForExistingScamTokens();

    if (walletInfo.hardwareWalletType == HardwareWalletType.ledger) {
      _evmChainPrivateKey = EvmLedgerCredentials(walletInfo.address);
      walletAddresses.address = walletInfo.address;
    } else if (walletInfo.hardwareWalletType == HardwareWalletType.bitbox) {
      _evmChainPrivateKey = EvmBitboxCredentials(walletInfo.address);
      walletAddresses.address = walletInfo.address;
    } else if (walletInfo.hardwareWalletType == HardwareWalletType.trezor) {
      _evmChainPrivateKey = EvmTrezorCredentials(walletInfo.address);
      walletAddresses.address = walletInfo.address;
    } else {
      _evmChainPrivateKey = await getPrivateKey(
        mnemonic: _mnemonic,
        privateKey: _hexPrivateKey,
        password: _password,
        passphrase: passphrase,
      );
      walletAddresses.address = _evmChainPrivateKey.address.hexEip55;
    }
    await save();
  }

  Future<void> _checkForExistingScamTokens() async {
    final baseCurrencySymbols = CryptoCurrency.all.map((e) => e.title.toUpperCase()).toList();

    for (var token in erc20Currencies) {
      bool isPotentialScam = false;

      bool isWhitelisted = getDefaultTokenContractAddresses
          .any((element) => element.toLowerCase() == token.contractAddress.toLowerCase());

      final tokenSymbol = token.title.toUpperCase();

      // check if the token symbol is the same as any of the base currencies symbols (ETH, SOL, POL, TRX, etc):
      // if it is, then it's probably a scam unless it's in the whitelist
      if (baseCurrencySymbols.contains(tokenSymbol.trim().toUpperCase()) && !isWhitelisted) {
        isPotentialScam = true;
      }

      if (isPotentialScam) {
        token.isPotentialScam = true;
        token.iconPath = null;
        await token.save();
      }

      // For fixing wrongly classified tokens
      if (!isPotentialScam && token.isPotentialScam) {
        token.isPotentialScam = false;

        if (token.iconPath == null || token.iconPath!.isEmpty) {
          try {
            token.iconPath = CryptoCurrency.all
                .firstWhere((e) => e.title.toUpperCase() == token.symbol.toUpperCase())
                .iconPath;
          } catch (_) {
            printV("Token ${token.symbol} does not have an icon path");
          }
        }

        await token.save();
      }
    }
  }

  @override
  int calculateEstimatedFee(TransactionPriority priority, int? amount) {
    {
      try {
        if (priority is EVMChainTransactionPriority) {
          final priorityFee = EtherAmount.fromInt(EtherUnit.gwei, priority.tip).getInWei.toInt();

          int maxFeePerGas;
          if (gasBaseFee != null) {
            // MaxFeePerGas with EIP1559;
            maxFeePerGas = gasBaseFee! + priorityFee;
          } else {
            // MaxFeePerGas with gasPrice;
            maxFeePerGas = gasPrice;
            printV('MaxFeePerGas with gasPrice: $maxFeePerGas');
          }

          final totalGasFee = estimatedGasUnits * maxFeePerGas;
          return totalGasFee;
        }

        return 0;
      } catch (e) {
        return 0;
      }
    }
  }

  /// Allows more customization to the fetch estimatedFees flow.
  ///
  /// We are able to pass in:
  /// - The exact amount the user wants to send,
  /// - The addressHex for the receiving wallet,
  /// - A contract address which would be essential in determining if to calculate the estimate for ERC20 or native ETH
  Future<GasParamsHandler> calculateActualEstimatedFeeForCreateTransaction({
    required amount,
    required String? contractAddress,
    required String receivingAddressHex,
    required TransactionPriority priority,
    Uint8List? data,
  }) async {
    try {
      if (priority is EVMChainTransactionPriority) {
        final priorityFee = EtherAmount.fromInt(EtherUnit.gwei, priority.tip).getInWei.toInt();

        int maxFeePerGas;
        int adjustedGasPrice;

        bool isPolygon = _client.chainId == 137;

        if (gasBaseFee != null) {
          // MaxFeePerGas with EIP1559;
          maxFeePerGas = gasBaseFee! + priorityFee;
        } else {
          // MaxFeePerGas with gasPrice
          maxFeePerGas = gasPrice + priorityFee;
        }

        adjustedGasPrice = maxFeePerGas;

        // Polygon has a minimum priority fee of 25 gwei
        if (isPolygon) {
          int minPriorityFee = 25;
          int minPriorityFeeWei =
              EtherAmount.fromInt(EtherUnit.gwei, minPriorityFee).getInWei.toInt();

          // Calculate  user selected priority-based additional fee on top of minimum
          int additionalPriorityFee = 0;
          switch (priority) {
            case EVMChainTransactionPriority.slow:
              // We use minimum priority fee only
              additionalPriorityFee = 0;
              break;
            case EVMChainTransactionPriority.medium:
              // We add 15 gwei on top of minimum
              additionalPriorityFee = EtherAmount.fromInt(EtherUnit.gwei, 15).getInWei.toInt();
              break;
            case EVMChainTransactionPriority.fast:
              // We add 35 gwei on top of minimum
              additionalPriorityFee = EtherAmount.fromInt(EtherUnit.gwei, 35).getInWei.toInt();
              break;
          }

          int totalPriorityFee = minPriorityFeeWei + additionalPriorityFee;
          adjustedGasPrice = gasPrice + totalPriorityFee;
          maxFeePerGas = gasPrice + totalPriorityFee;
        }

        final estimatedGas = await _client.getEstimatedGasUnitsForTransaction(
          contractAddress: contractAddress,
          senderAddress: _evmChainPrivateKey.address,
          value: EtherAmount.fromBigInt(EtherUnit.wei, amount!),
          gasPrice: EtherAmount.fromInt(EtherUnit.wei, adjustedGasPrice),
          toAddress: EthereumAddress.fromHex(receivingAddressHex),
          maxFeePerGas: EtherAmount.fromInt(EtherUnit.wei, maxFeePerGas),
          data: data,
        );

        final totalGasFee = estimatedGas * adjustedGasPrice;

        return GasParamsHandler(
          estimatedGasUnits: estimatedGas,
          estimatedGasFee: totalGasFee,
          maxFeePerGas: maxFeePerGas,
          gasPrice: adjustedGasPrice,
        );
      }
      return GasParamsHandler.zero();
    } catch (e) {
      return GasParamsHandler.zero();
    }
  }

  @override
  Future<void> changePassword(String password) {
    throw UnimplementedError("changePassword");
  }

  @override
  Future<void> close({bool shouldCleanup = false}) async {
    _client.stop();
    _transactionsUpdateTimer?.cancel();
    _updateFeesTimer?.cancel();
  }

  @action
  @override
  Future<void> connectToNode({required Node node}) async {
    try {
      syncStatus = ConnectingSyncStatus();

      final isConnected = _client.connect(node);

      if (!isConnected) {
        throw Exception("${walletInfo.type.name.toUpperCase()} Node connection failed");
      }

      _client.setListeners(_evmChainPrivateKey.address, _onNewTransaction);

      _setTransactionUpdateTimer();

      syncStatus = ConnectedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  @action
  @override
  Future<void> startSync() async {
    try {
      syncStatus = AttemptingSyncStatus();

      // Verify node health before attempting to sync
      final isHealthy = await checkNodeHealth();
      if (!isHealthy) {
        syncStatus = FailedSyncStatus();
        return;
      }

      await _updateBalance();
      await _updateTransactions();
      await _updateEstimatedGasFeeParams();

      _updateFeesTimer ??= Timer.periodic(const Duration(seconds: 30), (timer) async {
        await _updateEstimatedGasFeeParams();
      });
      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
  }

  Future<void> _updateEstimatedGasFeeParams() async {
    gasBaseFee = await _client.getGasBaseFee();

    gasPrice = await _client.getGasUnitPrice();

    estimatedGasUnits = await _client.getEstimatedGasUnitsForTransaction(
      senderAddress: _evmChainPrivateKey.address,
      toAddress: _evmChainPrivateKey.address,
      gasPrice: EtherAmount.fromInt(EtherUnit.wei, gasPrice),
      value: EtherAmount.fromBigInt(EtherUnit.wei, BigInt.one),
    );
  }

  @override
  Future<PendingTransaction> createTransaction(Object credentials) async {
    final _credentials = credentials as EVMChainTransactionCredentials;
    final outputs = _credentials.outputs;
    final hasMultiDestination = outputs.length > 1;

    final String? opReturnMemo = outputs.first.memo;

    String? hexOpReturnMemo;
    if (opReturnMemo != null) {
      hexOpReturnMemo =
          '0x${opReturnMemo.codeUnits.map((char) => char.toRadixString(16).padLeft(2, '0')).join()}';
    }

    final CryptoCurrency transactionCurrency =
        balance.keys.firstWhere((element) => element.title == _credentials.currency.title);

    final currencyBalance = balance[transactionCurrency]!;
    BigInt totalAmount = BigInt.zero;
    BigInt estimatedFeesForTransaction = BigInt.zero;
    int exponent = transactionCurrency is Erc20Token ? transactionCurrency.decimal : 18;
    String? contractAddress;
    int estimatedGasUnitsForTransaction = 0;
    int maxFeePerGasForTransaction = 0;
    String toAddress = _credentials.outputs.first.isParsedAddress
        ? _credentials.outputs.first.extractedAddress!
        : _credentials.outputs.first.address;

    if (transactionCurrency is Erc20Token) {
      contractAddress = transactionCurrency.contractAddress;
    }

    // so far this can not be made with Ethereum as Ethereum does not support multiple recipients
    if (hasMultiDestination) {
      if (outputs.any((item) => item.sendAll || (item.formattedCryptoAmount ?? 0) <= 0)) {
        throw EVMChainTransactionCreationException(transactionCurrency);
      }

      final totalOriginalAmount = EVMChainFormatter.parseEVMChainAmountToDouble(
          outputs.fold(0, (acc, value) => acc + (value.formattedCryptoAmount ?? 0)));

      totalAmount = parseFixed(
          EVMChainFormatter.truncateDecimals(totalOriginalAmount.toString(), exponent), exponent);

      final gasFeesModel = await calculateActualEstimatedFeeForCreateTransaction(
        amount: totalAmount,
        receivingAddressHex: toAddress,
        priority: _credentials.priority!,
        contractAddress: contractAddress,
      );

      estimatedFeesForTransaction = BigInt.from(gasFeesModel.estimatedGasFee);
      estimatedGasUnitsForTransaction = gasFeesModel.estimatedGasUnits;
      maxFeePerGasForTransaction = gasFeesModel.maxFeePerGas;

      if (currencyBalance.balance < totalAmount) {
        throw EVMChainTransactionCreationException(transactionCurrency);
      }
    } else {
      final output = outputs.first;
      if (!output.sendAll) {
        final totalOriginalAmount =
            EVMChainFormatter.parseEVMChainAmountToDouble(output.formattedCryptoAmount ?? 0);

        totalAmount = parseFixed(
            EVMChainFormatter.truncateDecimals(totalOriginalAmount.toString(), exponent), exponent);
      }

      if (output.sendAll && transactionCurrency is Erc20Token) {
        totalAmount = currencyBalance.balance;
      }

      final gasFeesModel = await calculateActualEstimatedFeeForCreateTransaction(
        amount: totalAmount,
        receivingAddressHex: toAddress,
        priority: _credentials.priority!,
        contractAddress: contractAddress,
      );

      estimatedFeesForTransaction = BigInt.from(gasFeesModel.estimatedGasFee);
      estimatedGasUnitsForTransaction = gasFeesModel.estimatedGasUnits;
      maxFeePerGasForTransaction = gasFeesModel.maxFeePerGas;

      if (output.sendAll && transactionCurrency is! Erc20Token) {
        if (_client.chainId == 8453) {
          // Add a safety buffer for Base chain to account for gas price fluctuations
          // Use 1% buffer or minimum 1000 wei (0.000001 ETH), whichever is higher
          final gasBufferPercent =
              estimatedFeesForTransaction * BigInt.from(101) ~/ BigInt.from(100);
          final gasBufferMin = estimatedFeesForTransaction + BigInt.from(1000);
          final gasBuffer = gasBufferPercent > gasBufferMin ? gasBufferPercent : gasBufferMin;

          totalAmount = (currencyBalance.balance - gasBuffer);

          // Re-estimate gas with the correct amount to get more accurate gas estimation
          final refinedGasFeesModel = await calculateActualEstimatedFeeForCreateTransaction(
            amount: totalAmount,
            receivingAddressHex: toAddress,
            priority: _credentials.priority!,
            contractAddress: contractAddress,
          );

          // Use the higher of the two gas estimations to be safe
          final refinedGasFee = BigInt.from(refinedGasFeesModel.estimatedGasFee);
          estimatedFeesForTransaction = refinedGasFee > gasBuffer ? refinedGasFee : gasBuffer;
          estimatedGasUnitsForTransaction = refinedGasFeesModel.estimatedGasUnits;
          maxFeePerGasForTransaction = refinedGasFeesModel.maxFeePerGas;
        }

        // Final amount calculation with the higher gas estimation
        totalAmount = (currencyBalance.balance - estimatedFeesForTransaction);
      }

      // check the fees on the base currency (Eth/Polygon)
      if (estimatedFeesForTransaction > balance[currency]!.balance) {
        throw EVMChainTransactionFeesException(currency.title);
      }

      if (currencyBalance.balance < totalAmount) {
        throw EVMChainTransactionCreationException(transactionCurrency);
      }
    }

    if (transactionCurrency is Erc20Token &&
        walletInfo.hardwareWalletType == HardwareWalletType.ledger) {
      await (_evmChainPrivateKey as EvmLedgerCredentials)
          .provideERC20Info(transactionCurrency.contractAddress, _client.chainId);
    }

    final pendingEVMChainTransaction = await _client.signTransaction(
      estimatedGasUnits: estimatedGasUnitsForTransaction,
      privateKey: _evmChainPrivateKey,
      toAddress: toAddress,
      amount: totalAmount,
      gasFee: estimatedFeesForTransaction,
      priority: _credentials.priority!,
      currency: transactionCurrency,
      feeCurrency: switch (_client.chainId) { 1 => "ETH", 137 => "POL", 8453 => "ETH", _ => "ETH" },
      maxFeePerGas: maxFeePerGasForTransaction,
      exponent: exponent,
      contractAddress:
          transactionCurrency is Erc20Token ? transactionCurrency.contractAddress : null,
      data: hexOpReturnMemo,
      gasPrice: maxFeePerGasForTransaction,
    );

    return pendingEVMChainTransaction;
  }

  Future<PendingTransaction> createApprovalTransaction(BigInt amount, String spender,
      CryptoCurrency token, EVMChainTransactionPriority priority, String feeCurrency) async {
    final CryptoCurrency transactionCurrency =
        balance.keys.firstWhere((element) => element.title == token.title);
    assert(transactionCurrency is Erc20Token);

    final data = _client.getEncodedDataForApprovalTransaction(
      contractAddress: EthereumAddress.fromHex((transactionCurrency as Erc20Token).contractAddress),
      value: EtherAmount.fromBigInt(EtherUnit.wei, amount),
      toAddress: EthereumAddress.fromHex(spender),
    );

    final gasFeesModel = await calculateActualEstimatedFeeForCreateTransaction(
      amount: amount,
      receivingAddressHex: spender,
      priority: priority,
      contractAddress: transactionCurrency.contractAddress,
      data: data,
    );

    return _client.signApprovalTransaction(
      privateKey: _evmChainPrivateKey,
      spender: spender,
      amount: amount,
      priority: priority,
      gasFee: BigInt.from(gasFeesModel.estimatedGasFee),
      maxFeePerGas: gasFeesModel.maxFeePerGas,
      feeCurrency: feeCurrency,
      estimatedGasUnits: gasFeesModel.estimatedGasUnits,
      exponent: transactionCurrency.decimal,
      contractAddress: transactionCurrency.contractAddress,
      gasPrice: gasFeesModel.gasPrice,
    );
  }

  Future<void> _updateTransactions() async {
    try {
      if (_isTransactionUpdating) {
        return;
      }

      final isProviderEnabled = await checkIfScanProviderIsEnabled();

      if (!isProviderEnabled) {
        return;
      }

      _isTransactionUpdating = true;
      final transactions = await fetchTransactions();
      transactionHistory.addMany(transactions);
      await transactionHistory.save();
      _isTransactionUpdating = false;
    } catch (_) {
      _isTransactionUpdating = false;
    }
  }

  @override
  Future<Map<String, EVMChainTransactionInfo>> fetchTransactions() async {
    final List<EVMChainTransactionModel> transactions = [];
    final List<Future<List<EVMChainTransactionModel>>> erc20TokensTransactions = [];

    final address = _evmChainPrivateKey.address.hex;
    final externalTransactions = await _client.fetchTransactions(address);
    final internalTransactions = await _client.fetchInternalTransactions(address);

    for (var transaction in externalTransactions) {
      final evmSignatureName = analyzeTransaction(transaction.input);

      if (evmSignatureName != 'depositWithExpiry' && evmSignatureName != 'transfer') {
        transaction.evmSignatureName = evmSignatureName;
        transactions.add(transaction);
      }
    }

    for (var token in balance.keys) {
      if (token is Erc20Token) {
        erc20TokensTransactions.add(_client.fetchTransactions(
          address,
          contractAddress: token.contractAddress,
        ));
      }
    }

    final tokensTransaction = await Future.wait(erc20TokensTransactions);
    transactions.addAll(tokensTransaction.expand((element) => element));
    transactions.addAll(internalTransactions);

    final Map<String, EVMChainTransactionInfo> result = {};

    for (var transactionModel in transactions) {
      if (transactionModel.isError) {
        continue;
      }

      result[transactionModel.hash] = getTransactionInfo(transactionModel, address);
    }

    return result;
  }

  String? analyzeTransaction(String? transactionInput) {
    if (transactionInput == '0x' || transactionInput == null || transactionInput.isEmpty) {
      return 'simpleTransfer';
    }

    final methodSignature =
        transactionInput.length >= 10 ? transactionInput.substring(0, 10) : null;

    return methodSignatureToType[methodSignature];
  }

  @override
  Object get keys => throw UnimplementedError("keys");

  @override
  Future<void> rescan({required int height}) {
    throw UnimplementedError("rescan");
  }

  @override
  Future<void> save() async {
    if (!(await WalletKeysFile.hasKeysFile(walletInfo.name, walletInfo.type))) {
      await saveKeysFile(_password, encryptionFileUtils);
      saveKeysFile(_password, encryptionFileUtils, true);
    }

    await walletAddresses.updateAddressesInBox();
    final path = await makePath();
    await encryptionFileUtils.write(path: path, password: _password, data: toJSON());
    await transactionHistory.save();
  }

  @override
  String? get seed => _mnemonic;

  @override
  String? get privateKey => evmChainPrivateKey is EthPrivateKey
      ? HEX.encode((evmChainPrivateKey as EthPrivateKey).privateKey)
      : null;

  @override
  WalletKeysData get walletKeysData => WalletKeysData(
        mnemonic: _mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
      );

  String toJSON() => json.encode({
        'mnemonic': _mnemonic,
        'private_key': privateKey,
        'balance': balance[currency]!.toJSON(),
        'passphrase': passphrase,
      });

  Future<void> _updateBalance() async {
    balance[currency] = await _fetchEVMChainBalance();

    await _fetchErc20Balances();
    await save();
  }

  Future<EVMChainERC20Balance> _fetchEVMChainBalance() async {
    final balance = await _client.getBalance(_evmChainPrivateKey.address);
    return EVMChainERC20Balance(balance.getInWei);
  }

  Future<void> _fetchErc20Balances() async {
    for (var token in evmChainErc20TokensBox.values) {
      try {
        if (token.enabled) {
          balance[token] = await _client.fetchERC20Balances(
            _evmChainPrivateKey.address,
            token.contractAddress,
          );
        } else {
          balance.remove(token);
        }
      } catch (_) {}
    }
  }

  Future<EthPrivateKey> getPrivateKey({
    String? mnemonic,
    String? privateKey,
    required String password,
    String? passphrase,
  }) async {
    assert(mnemonic != null || privateKey != null);

    if (privateKey != null) {
      return EthPrivateKey.fromHex(privateKey);
    }

    final seed = bip39.mnemonicToSeed(mnemonic!, passphrase: passphrase ?? '');

    final root = bip32.BIP32.fromSeed(seed);

    const hdPathEVMChain = "m/44'/60'/0'/0";
    const index = 0;
    final addressAtIndex = root.derivePath("$hdPathEVMChain/$index");

    return EthPrivateKey.fromHex(HEX.encode(addressAtIndex.privateKey as List<int>));
  }

  @override
  Future<void>? updateBalance() async => await _updateBalance();

  List<Erc20Token> get erc20Currencies => evmChainErc20TokensBox.values.toList();

  Future<void> addErc20Token(Erc20Token token) async {
    String? iconPath;

    if ((token.iconPath == null || token.iconPath!.isEmpty) && !token.isPotentialScam) {
      try {
        iconPath = CryptoCurrency.all
            .firstWhere((element) => element.title.toUpperCase() == token.symbol.toUpperCase())
            .iconPath;
      } catch (_) {}
    } else if (!token.isPotentialScam) {
      iconPath = token.iconPath;
    }

    final newToken = createNewErc20TokenObject(token, iconPath);

    if (newToken.enabled) {
      try {
        final erc20Balance = await _client.fetchERC20Balances(
          _evmChainPrivateKey.address,
          newToken.contractAddress,
        );

        balance[newToken] = erc20Balance;

        await evmChainErc20TokensBox.put(newToken.contractAddress, newToken);
      } on Exception catch (_) {
        rethrow;
      }
    } else {
      await evmChainErc20TokensBox.put(newToken.contractAddress, newToken);
      balance.remove(newToken);
    }
  }

  Future<void> deleteErc20Token(Erc20Token token) async {
    await token.delete();

    balance.remove(token);
    await removeTokenTransactionsInHistory(token);
    _updateBalance();
  }

  Future<void> removeTokenTransactionsInHistory(Erc20Token token) async {
    transactionHistory.transactions.removeWhere((key, value) => value.tokenSymbol == token.title);
    await transactionHistory.save();
  }

  Future<Erc20Token?> getErc20Token(String contractAddress, String chainName) async =>
      await _client.getErc20Token(contractAddress, chainName);

  void _onNewTransaction() {
    _updateBalance();
    _updateTransactions();
  }

  @override
  Future<void> renameWalletFiles(String newWalletName) async {
    final transactionHistoryFileNameForWallet = getTransactionHistoryFileName();

    final currentWalletPath = await pathForWallet(name: walletInfo.name, type: type);
    final currentWalletFile = File(currentWalletPath);

    final currentDirPath = await pathForWalletDir(name: walletInfo.name, type: type);
    final currentTransactionsFile = File('$currentDirPath/$transactionHistoryFileNameForWallet');

    // Copies current wallet files into new wallet name's dir and files
    if (currentWalletFile.existsSync()) {
      final newWalletPath = await pathForWallet(name: newWalletName, type: type);
      await currentWalletFile.copy(newWalletPath);
    }
    if (currentTransactionsFile.existsSync()) {
      final newDirPath = await pathForWalletDir(name: newWalletName, type: type);
      await currentTransactionsFile.copy('$newDirPath/$transactionHistoryFileNameForWallet');
    }

    // Delete old name's dir and files
    await Directory(currentDirPath).delete(recursive: true);
  }

  void _setTransactionUpdateTimer() {
    if (_transactionsUpdateTimer?.isActive ?? false) {
      _transactionsUpdateTimer!.cancel();
    }

    _transactionsUpdateTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      _updateTransactions();
      _updateBalance();
    });
  }

  /// Scan Providers:
  ///
  /// EtherScan for Ethereum.
  ///
  /// PolygonScan for Polygon.
  ///
  /// BaseScan for Base.
  void updateScanProviderUsageState(bool isEnabled) {
    if (isEnabled) {
      _updateTransactions();
      _setTransactionUpdateTimer();
    } else {
      _transactionsUpdateTimer?.cancel();
    }
  }

  @override
  Future<String> signMessage(String message, {String? address}) async {
    return bytesToHex(await _evmChainPrivateKey.signPersonalMessage(ascii.encode(message)));
  }

  @override
  Future<bool> verifyMessage(String message, String signature, {String? address}) async {
    if (address == null) {
      return false;
    }
    final recoveredAddress = EthSigUtil.recoverPersonalSignature(
      message: ascii.encode(message),
      signature: signature,
    );
    return recoveredAddress.toUpperCase() == address.toUpperCase();
  }

  Web3Client? getWeb3Client() => _client.getWeb3Client();

  @override
  String get password => _password;

  @override
  final String? passphrase;
}

class GasParamsHandler {
  final int estimatedGasUnits;
  final int estimatedGasFee;
  final int maxFeePerGas;
  final int gasPrice;

  GasParamsHandler(
      {required this.estimatedGasUnits,
      required this.estimatedGasFee,
      required this.maxFeePerGas,
      required this.gasPrice});

  static GasParamsHandler zero() {
    return GasParamsHandler(
      estimatedGasUnits: 0,
      estimatedGasFee: 0,
      maxFeePerGas: 0,
      gasPrice: 0,
    );
  }
}
