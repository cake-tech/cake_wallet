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
import 'package:cw_core/transaction_direction.dart';
import 'package:cw_core/transaction_priority.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_keys_file.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_client_factory.dart';
import 'package:cw_evm/evm_chain_default_tokens.dart';
import 'package:cw_evm/evm_chain_exceptions.dart';
import 'package:cw_evm/utils/evm_chain_formatter.dart';
import 'package:cw_evm/evm_chain_registry.dart';
import 'package:cw_evm/evm_chain_transaction_credentials.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_model.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/utils/evm_chain_utils.dart';
import 'package:cw_evm/utils/network_chain_utils.dart';
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

import 'contract/erc20.dart';
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

class EVMChainWallet = EVMChainWalletBase with _$EVMChainWallet;

abstract class EVMChainWalletBase
    extends WalletBase<EVMChainERC20Balance, EVMChainTransactionHistory, EVMChainTransactionInfo>
    with Store, WalletKeysFile {
  EVMChainWalletBase({
    required WalletInfo walletInfo,
    required DerivationInfo derivationInfo,
    required EVMChainClient client,
    required CryptoCurrency nativeCurrency,
    String? mnemonic,
    String? privateKey,
    required String password,
    EVMChainERC20Balance? initialBalance,
    required this.encryptionFileUtils,
    this.passphrase,
    int? initialChainId,
  })  : syncStatus = const NotConnectedSyncStatus(),
        _password = password,
        _mnemonic = mnemonic,
        _hexPrivateKey = privateKey,
        _isTransactionUpdating = false,
        _client = client,
        selectedChainId = initialChainId ?? _getInitialChainId(walletInfo.type),
        walletAddresses = EVMChainWalletAddresses(walletInfo),
        balance = ObservableMap<CryptoCurrency, EVMChainERC20Balance>.of(
          {
            nativeCurrency: initialBalance ?? EVMChainERC20Balance(BigInt.zero),
          },
        ),
        super(walletInfo, derivationInfo) {
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

  late Box<Erc20Token> evmChainErc20TokensBox;

  late final Credentials _evmChainPrivateKey;

  Credentials get evmChainPrivateKey => _evmChainPrivateKey;

  late EVMChainClient _client;

  @override
  int? get chainId => selectedChainId;

  /// Currently selected chain ID for this wallet
  @observable
  int selectedChainId;

  /// Get chain configuration for currently selected chain
  @computed
  ChainConfig? get selectedChainConfig {
    final registry = EvmChainRegistry();
    return registry.getChainConfig(selectedChainId);
  }

  @override
  @computed
  CryptoCurrency get currency {
    final config = selectedChainConfig;
    if (config != null) {
      return config.nativeCurrency;
    }

    return super.currency;
  }

  bool get hasPriorityFee => EVMChainUtils.hasPriorityFee(selectedChainId);

  /// Get initial chain ID from registry based on wallet type
  static int _getInitialChainId(WalletType walletType) {
    final registry = EvmChainRegistry();
    final chainConfig = registry.getChainConfigByWalletType(walletType);
    return chainConfig?.chainId ?? 1; // Default to Ethereum if not found
  }

  @observable
  String? nativeTxEstimatedFee;

  @observable
  String? erc20TxEstimatedFee;

  bool _isTransactionUpdating;

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

  //! Chain selection methods

  /// Select a different EVM network chain for this wallet
  ///
  /// This allows switching between EVM networks (Ethereum, Polygon, Base, Arbitrum, etc.)
  /// without creating a new wallet. The selected chain ID is stored, the client is
  /// immediately updated, and the wallet automatically connects to the node, updates
  /// balance, and refreshes transactions for the selected network.
  ///
  /// Transactions are stored in separate files per network (based on chainId), so switching
  /// networks automatically loads transactions from the correct file.
  @action
  Future<void> selectChain(int chainId, {required Node node}) async {
    if (EvmChainRegistry().getChainConfig(chainId) == null) {
      throw Exception('Chain config not found for chainId: $chainId');
    }

    if (selectedChainId == chainId) return;

    _client.stop();

    balance.clear();

    selectedChainId = chainId;
    _client = EVMChainClientFactory.createClient(selectedChainId);

    // Automatically connect to node for the selected chain
    await connectToNode(node: node);

    // Reload ERC20 tokens box for the new chain
    await initErc20TokensBox();

    // Reload transaction history from the new chain's file
    await transactionHistory.init();

    await save();

    await startSync();
  }

  void addInitialTokens() {
    final initialErc20Tokens = EVMChainDefaultTokens.getDefaultTokensByChainId(selectedChainId);

    for (final token in initialErc20Tokens) {
      if (!evmChainErc20TokensBox.containsKey(token.contractAddress)) {
        evmChainErc20TokensBox.put(token.contractAddress, token);
      } else {
        // update existing token
        final existingToken = evmChainErc20TokensBox.get(token.contractAddress);
        evmChainErc20TokensBox.put(
          token.contractAddress,
          Erc20Token.copyWith(token, enabled: existingToken!.enabled),
        );
      }
    }
  }

  List<String> get getDefaultTokenContractAddresses =>
      EVMChainDefaultTokens.getDefaultTokenAddresses(selectedChainId);

  Future<void> initErc20TokensBox() async {
    // Migration for old WalletType.ethereum wallets:
    // Old wallets used a global erc20TokensBox (shared across all wallets).
    // New system uses wallet-specific, chain-specific boxes.
    // This checks if migration is needed and runs it once.
    if (walletInfo.type == WalletType.ethereum) {
      try {
        // Try to access erc20TokensBox - if it exists, migration already ran
        final _ = erc20TokensBox;
        // Migration done, proceed with normal chain-specific logic below
      } catch (_) {
        // erc20TokensBox doesn't exist yet, run migration from global box
        await _initEthereumErc20TokensBox();
        return;
      }
    }

    final chainId = selectedChainId;

    final boxName = EVMChainUtils.getErc20TokensBoxName(walletInfo.name, chainId);

    // Close existing box if it's already open (for chain switching)
    try {
      if (evmChainErc20TokensBox.isOpen) {
        await evmChainErc20TokensBox.close();
      }
    } catch (_) {
      // Box might not be initialized yet, ignore
    }

    // Check if box is already open, if so use it, otherwise open it
    if (CakeHive.isBoxOpen(boxName)) {
      evmChainErc20TokensBox = CakeHive.box<Erc20Token>(boxName);
    } else {
      evmChainErc20TokensBox = await CakeHive.openBox<Erc20Token>(boxName);
    }

    addInitialTokens();
  }

  /// Ethereum-specific initialization with backward compatibility
  Future<void> _initEthereumErc20TokensBox() async {
    // Opens a box specific to this wallet
    evmChainErc20TokensBox = await CakeHive.openBox<Erc20Token>(
      "${walletInfo.name.replaceAll(" ", "_")}_${Erc20Token.ethereumBoxName}",
    );

    erc20TokensBox = await CakeHive.openBox<Erc20Token>(Erc20Token.boxName);

    if (erc20TokensBox.isEmpty) {
      if (evmChainErc20TokensBox.isEmpty) addInitialTokens();
      return;
    }

    final allValues = erc20TokensBox.values.toList();

    // Clear and delete the old token box
    await erc20TokensBox.clear();
    await erc20TokensBox.deleteFromDisk();

    // Add all the previous tokens with configs to the new box
    await evmChainErc20TokensBox.addAll(allValues);
  }

  String getTransactionHistoryFileName() =>
      EVMChainUtils.getTransactionHistoryFileName(selectedChainId);

  Future<bool> checkIfScanProviderIsEnabled() async {
    final key = EVMChainUtils.getScanProviderPreferenceKey(selectedChainId);
    return (await sharedPrefs.future).getBool(key) ?? true;
  }

  EVMChainTransactionInfo getTransactionInfo(
    EVMChainTransactionModel transactionModel,
    String address,
  ) {
    return EVMChainTransactionInfo(
      id: transactionModel.hash,
      height: transactionModel.blockNumber,
      ethAmount: transactionModel.amount,
      direction: transactionModel.from == address
          ? TransactionDirection.outgoing
          : TransactionDirection.incoming,
      isPending: false,
      date: transactionModel.date,
      confirmations: transactionModel.confirmations,
      ethFee: BigInt.from(transactionModel.gasUsed) * transactionModel.gasPrice,
      exponent: transactionModel.tokenDecimal ?? 18,
      tokenSymbol: transactionModel.tokenSymbol ??
          EVMChainUtils.getDefaultTokenSymbol(transactionModel.chainId),
      to: transactionModel.to,
      from: transactionModel.from,
      evmSignatureName: transactionModel.evmSignatureName,
      contractAddress: transactionModel.contractAddress,
      chainId: transactionModel.chainId,
    );
  }

  Erc20Token createNewErc20TokenObject(Erc20Token token, String? iconPath) {
    return Erc20Token(
      name: token.name,
      symbol: token.symbol,
      contractAddress: token.contractAddress,
      decimal: token.decimal,
      enabled: token.enabled,
      tag: token.tag ?? EVMChainUtils.getDefaultTokenTag(selectedChainId),
      iconPath: iconPath,
      isPotentialScam: token.isPotentialScam,
    );
  }

  EVMChainTransactionHistory setUpTransactionHistory(
    WalletInfo walletInfo,
    String password,
    EncryptionFileUtils encryptionFileUtils,
  ) {
    return EVMChainTransactionHistory(
      walletInfo: walletInfo,
      password: password,
      encryptionFileUtils: encryptionFileUtils,
      getCurrentChainId: () => selectedChainId,
    );
  }

  String _getUSDCContractAddress() {
    return switch (selectedChainId) {
      1 => "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48",
      137 => "0x2791bca1f2de4661ed88a30c99a7a9449aa84174",
      8453 => "0x833589fcd6edb6e08f4c7c32d4f71b54bda02913",
      42161 => "0xaf88d065e77c8cC2239327C5EDb3A432268e5831",
      _ => throw Exception("Unsupported chain ID: $selectedChainId"),
    };
  }

  @override
  Future<bool> checkNodeHealth() async {
    try {
      // Check native balance
      await _client.getBalance(_evmChainPrivateKey.address);

      // Check USDC token balance
      String usdcContractAddress = _getUSDCContractAddress();

      await _client.fetchERC20Balances(_evmChainPrivateKey.address, usdcContractAddress);

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

    switch (walletInfo.hardwareWalletType) {
      case HardwareWalletType.ledger:
        _evmChainPrivateKey = EvmLedgerCredentials(walletInfo.address);
        walletAddresses.address = walletInfo.address;
        break;
      case HardwareWalletType.bitbox:
        _evmChainPrivateKey = EvmBitboxCredentials(walletInfo.address);
        walletAddresses.address = walletInfo.address;
        break;
      case HardwareWalletType.trezor:
        _evmChainPrivateKey = EvmTrezorCredentials(walletInfo.address);
        walletAddresses.address = walletInfo.address;
        break;
      case HardwareWalletType.cupcake:
      case HardwareWalletType.coldcard:
      case HardwareWalletType.seedsigner:
      case HardwareWalletType.keystone:
        throw UnimplementedError();
      case null:
        _evmChainPrivateKey = await getPrivateKey(
          mnemonic: _mnemonic,
          privateKey: _hexPrivateKey,
          password: _password,
          passphrase: passphrase,
        );
        walletAddresses.address = _evmChainPrivateKey.address.hexEip55;
        break;
    }

    // Ensure balance is initialized for current currency (in case currency changed)
    if (!balance.containsKey(currency)) {
      balance[currency] = EVMChainERC20Balance(BigInt.zero);
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
  int calculateEstimatedFee(TransactionPriority priority, int? amount) => 0;

  @override
  Future<void> updateEstimatedFeesParams(TransactionPriority? priority) async =>
      await _getEstimatedFees(priority);

  Future<void> _getEstimatedFees(TransactionPriority? priority) async {
    final nativeFee = await _getNativeTxFee(priority);
    nativeTxEstimatedFee = nativeFee.toString();

    final erc20Fee = await _getErc20TxFee(priority);
    erc20TxEstimatedFee = erc20Fee.toString();
  }

  Future<int> _getNativeTxFee(TransactionPriority? priority) async {
    try {
      int priorityFee = 0;
      if (hasPriorityFee) {
        if (priority is EVMChainTransactionPriority) {
          priorityFee = getTotalPriorityFee(priority);
        }
      }

      final gasPrice = await _client.getGasUnitPrice();
      final gasBaseFee = await _client.getGasBaseFee();

      final gasUnits = await _client.getEstimatedGasUnitsForTransaction(
        senderAddress: evmChainPrivateKey.address,
        toAddress: evmChainPrivateKey.address,
        gasPrice: EtherAmount.fromInt(EtherUnit.wei, gasPrice),
        value: EtherAmount.fromBigInt(EtherUnit.wei, BigInt.from(0.0000000001)),
      );

      int maxFeePerGas = gasBaseFee != null ? (gasBaseFee + priorityFee) : (gasPrice + priorityFee);
      final totalGasFee = gasUnits * maxFeePerGas;
      return totalGasFee;
    } catch (e) {
      printV(e.toString());
      return 0;
    }
  }

  Future<int> _getErc20TxFee(TransactionPriority? priority) async {
    try {
      int priorityFee = 0;
      if (hasPriorityFee) {
        if (priority is EVMChainTransactionPriority) {
          priorityFee = getTotalPriorityFee(priority);
        }
      }

      final gasPrice = await _client.getGasUnitPrice();
      final gasBaseFee = await _client.getGasBaseFee();

      final gasUnits = await _client.getEstimatedGasUnitsForTransaction(
        senderAddress: evmChainPrivateKey.address,
        toAddress: evmChainPrivateKey.address,
        contractAddress: _getUSDCContractAddress(), // Using USDC for default estimation
        gasPrice: EtherAmount.fromInt(EtherUnit.wei, gasPrice),
        value: EtherAmount.fromBigInt(EtherUnit.wei, BigInt.from(0.0000000001)),
      );

      int maxFeePerGas = gasBaseFee != null ? (gasBaseFee + priorityFee) : (gasPrice + priorityFee);
      final totalGasFee = gasUnits * maxFeePerGas;
      return totalGasFee;
    } catch (e) {
      printV(e.toString());
      return 0;
    }
  }

  int getTotalPriorityFee(EVMChainTransactionPriority priority) =>
      EVMChainUtils.getTotalPriorityFee(priority, selectedChainId);

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
    required TransactionPriority? priority,
    Uint8List? data,
  }) async {
    try {
      int priorityFee = 0;
      if (hasPriorityFee && priority != null) {
        if (priority is EVMChainTransactionPriority) {
          priorityFee = getTotalPriorityFee(priority);
        }
      }

      final gasBaseFee = await _client.getGasBaseFee();
      final gasPrice = await _client.getGasUnitPrice();

      int maxFeePerGas;
      int adjustedGasPrice;

      if (gasBaseFee != null) {
        // For chains with base fee, add priority fee (if supported) and a buffer to account for base fee increases
        // Base fee can increase between estimation and transaction submission
        final baseFeeWithPriority = gasBaseFee + priorityFee;
        
        // For chains without priority fees (e.g., Arbitrum), use a smaller buffer (5%)
        // For chains with priority fees, use a larger buffer (10%) to account for both base fee and priority fee volatility
        final bufferMultiplier = hasPriorityFee ? 110 : 105;
        final bufferPercent = (baseFeeWithPriority * bufferMultiplier) ~/ 100;
        final bufferMin = baseFeeWithPriority + (baseFeeWithPriority ~/ 100);
        maxFeePerGas = bufferPercent > bufferMin ? bufferPercent : bufferMin;
      } else {
        // Fallback to gasPrice if baseFee is not available
        maxFeePerGas = gasPrice + priorityFee;
      }

      adjustedGasPrice = maxFeePerGas;

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

      await Future.wait([
        _updateTransactions(),
        _getEstimatedFees(
          hasPriorityFee ? EVMChainTransactionPriority.medium : null,
        ), // We're using medium priority for default estimation
      ]);

      syncStatus = SyncedSyncStatus();
    } catch (e) {
      syncStatus = FailedSyncStatus();
    }
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

    final transactionCurrency = balance.keys.firstWhere(
        (currency) =>
            currency.title == _credentials.currency.title &&
            currency.tag == _credentials.currency.tag,
        orElse: () => throw Exception(
            'Currency ${_credentials.currency.title} ${_credentials.currency.tag} is not accessible in the wallet, try to enable it first.'));

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
        priority: _credentials.priority,
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
          EVMChainFormatter.truncateDecimals(totalOriginalAmount.toString(), exponent),
          exponent,
        );
      }

      if (output.sendAll && transactionCurrency is Erc20Token) {
        totalAmount = currencyBalance.balance;
      }

      final gasFeesModel = await calculateActualEstimatedFeeForCreateTransaction(
        amount: totalAmount,
        receivingAddressHex: toAddress,
        priority: _credentials.priority,
        contractAddress: contractAddress,
      );

      estimatedFeesForTransaction = BigInt.from(gasFeesModel.estimatedGasFee);
      estimatedGasUnitsForTransaction = gasFeesModel.estimatedGasUnits;
      maxFeePerGasForTransaction = gasFeesModel.maxFeePerGas;

      if (output.sendAll && transactionCurrency is! Erc20Token) {
        if (selectedChainId == 8453) {
          // Applying a small buffer to account for gas price fluctuations
          // 10% or minimum 10,000 wei, whichever is higher
          final refinedGasFee = estimatedFeesForTransaction;
          final gasBufferPercent = refinedGasFee * BigInt.from(110) ~/ BigInt.from(100);
          final gasBufferMin = refinedGasFee + BigInt.from(10000);
          final gasBuffer = gasBufferPercent > gasBufferMin ? gasBufferPercent : gasBufferMin;

          // Using the buffered fee for the final amount
          totalAmount = (currencyBalance.balance - gasBuffer);
          estimatedFeesForTransaction = gasBuffer;
        } else {
          // Calculating the final amount with the estimated gas fee
          totalAmount = (currencyBalance.balance - estimatedFeesForTransaction);
        }
      }

      // check the fees on the base currency
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
          .provideERC20Info(transactionCurrency.contractAddress, selectedChainId);
    }

    final pendingEVMChainTransaction = await _client.signTransaction(
      estimatedGasUnits: estimatedGasUnitsForTransaction,
      privateKey: _evmChainPrivateKey,
      toAddress: toAddress,
      amount: totalAmount,
      gasFee: estimatedFeesForTransaction,
      priority: _credentials.priority,
      currency: transactionCurrency,
      feeCurrency: switch (selectedChainId) { 137 => "POL", _ => "ETH" },
      maxFeePerGas: maxFeePerGasForTransaction,
      exponent: exponent,
      contractAddress:
          transactionCurrency is Erc20Token ? transactionCurrency.contractAddress : null,
      data: hexOpReturnMemo,
      gasPrice: maxFeePerGasForTransaction,
      useBlinkProtection: _credentials.useBlinkProtection,
    );

    return pendingEVMChainTransaction;
  }

  Future<PendingTransaction> createCallDataTransaction(
    String to,
    String dataHex,
    BigInt valueWei,
    EVMChainTransactionPriority? priority, {
    bool useBlinkProtection = true,
  }) async {
    // Estimate gas with the SAME call (sender, to, value, data)
    final gas = await calculateActualEstimatedFeeForCreateTransaction(
      amount: valueWei, // native value (usually 0 for ERC20 transfer)
      receivingAddressHex: to,
      priority: priority,
      contractAddress: null,
      data: _client.hexToBytes(dataHex),
    );

    final nativeCurrency = switch (selectedChainId) {
      137 => CryptoCurrency.maticpoly,
      8453 => CryptoCurrency.baseEth,
      42161 => CryptoCurrency.arbEth,
      _ => CryptoCurrency.eth,
    };

    // Fallback for nodes that fail estimate (non-zero)
    final gasUnits = gas.estimatedGasUnits == 0 ? 65000 : gas.estimatedGasUnits;

    // Sign raw (native) tx with callData
    return _client.signTransaction(
      privateKey: _evmChainPrivateKey,
      toAddress: to,
      amount: valueWei,
      gasFee: BigInt.from(gas.estimatedGasFee),
      estimatedGasUnits: gasUnits,
      maxFeePerGas: gas.maxFeePerGas,
      priority: priority,
      currency: nativeCurrency,
      feeCurrency: nativeCurrency.title,
      exponent: 18,
      contractAddress: null,
      data: dataHex,
      gasPrice: gas.gasPrice,
      useBlinkProtection: useBlinkProtection,
    );
  }

  Future<PendingTransaction> createApprovalTransaction(BigInt amount, String spender,
      CryptoCurrency token, EVMChainTransactionPriority? priority, String feeCurrency,
      {bool useBlinkProtection = true}) async {
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
      useBlinkProtection: useBlinkProtection,
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
        'balance': balance[currency]?.toJSON() ?? EVMChainERC20Balance(BigInt.zero).toJSON(),
        'passphrase': passphrase,
        'selected_chain_id': selectedChainId,
      });

  Future<void> _updateBalance() async {
    balance[currency] = await _fetchEVMChainBalance();

    await _fetchErc20Balances();
    await save();
  }

  Future<EVMChainERC20Balance> _fetchEVMChainBalance() async {
    try {
      final balance = await _client.getBalance(_evmChainPrivateKey.address);

      return EVMChainERC20Balance(balance.getInWei);
    } catch (_) {
      return balance[currency] ?? EVMChainERC20Balance(BigInt.zero);
    }
  }

  bool _isTokenMatchingChain(Erc20Token token) {
    final registry = EvmChainRegistry();

    if (token.tag != null) {
      final chainConfig = registry.getChainConfigByTag(token.tag!);
      if (chainConfig != null) return chainConfig.chainId == selectedChainId;
    }

    if (currency.tag == null) return token.tag == currency.title;

    return token.tag?.toLowerCase() == currency.tag?.toLowerCase();
  }

  Future<void> _fetchErc20Balances() async {
    // Check if box is open before accessing it
    if (!evmChainErc20TokensBox.isOpen) {
      return;
    }

    // First, clean up any tokens in balance map that don't belong to current chain
    // This handles tokens from previous chains that might still be in the balance map
    final tokensInBalance = balance.keys.whereType<Erc20Token>().toList();
    final tokensInBox = evmChainErc20TokensBox.values.toList();
    final boxTokenAddresses = tokensInBox.map((t) => t.contractAddress.toLowerCase()).toSet();

    for (var token in tokensInBalance) {
      // Remove token if it's not in the current box or doesn't match current chain
      if (!boxTokenAddresses.contains(token.contractAddress.toLowerCase()) ||
          !_isTokenMatchingChain(token)) {
        balance.remove(token);
      }
    }

    // Get a snapshot of tokens from current box to avoid issues if box is closed during iteration
    final tokens = tokensInBox;

    for (var token in tokens) {
      // Check if box is still open before operating on tokens
      if (!evmChainErc20TokensBox.isOpen) break;

      if (!_isTokenMatchingChain(token)) {
        printV('NOTEE!!!: Token ${token.title} is not matching the currency ${currency.title}');
        try {
          await deleteErc20Token(token, shouldUpdateBalance: false);
        } catch (e) {
          balance.remove(token);
          printV('Error deleting token ${token.title}: $e');
        }
        continue;
      }

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

  Future<bool> isApprovalRequired(
      String tokenContract, String spender, BigInt requiredAmount) async {
    const zero = '0x0000000000000000000000000000000000000000';
    const evmNative = '0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE';

    final token = tokenContract.toLowerCase();
    if (token == zero || token == evmNative.toLowerCase()) return false;
    if (requiredAmount <= BigInt.zero) return false;

    try {
      final owner = _evmChainPrivateKey.address;
      final erc20 = ERC20(
        client: _client.getWeb3Client()!,
        address: EthereumAddress.fromHex(tokenContract),
        chainId: selectedChainId,
      );

      final allowance = await erc20.allowance(owner, EthereumAddress.fromHex(spender));

      return allowance < requiredAmount;
    } catch (e) {
      printV('approval-check error: $e');
      return true;
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
  @override
  Future<void> updateTransactionsHistory() async => await _updateTransactions();

  List<Erc20Token> get erc20Currencies {
    try {
      if (!evmChainErc20TokensBox.isOpen) return [];

      return evmChainErc20TokensBox.values.toList();
    } catch (_) {
      return [];
    }
  }

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

  Future<void> deleteErc20Token(Erc20Token token, {bool shouldUpdateBalance = true}) async {
    // Check if box is open before trying to delete
    if (!evmChainErc20TokensBox.isOpen) {
      balance.remove(token);
      return;
    }

    try {
      await token.delete();
    } catch (e) {
      // Token might be from a closed box, just remove from balance
      printV('Error deleting token from box: $e');
    }

    balance.remove(token);
    await removeTokenTransactionsInHistory(token);
    if (shouldUpdateBalance) {
      _updateBalance();
    }
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

  /// Static method to open an existing wallet
  static Future<EVMChainWallet> open({
    required String name,
    required String password,
    required WalletInfo walletInfo,
    required EncryptionFileUtils encryptionFileUtils,
  }) async {
    final hasKeysFile = await WalletKeysFile.hasKeysFile(name, walletInfo.type);
    final path = await pathForWallet(name: name, type: walletInfo.type);

    Map<String, dynamic>? data;
    try {
      final jsonSource = await encryptionFileUtils.read(path: path, password: password);
      data = json.decode(jsonSource) as Map<String, dynamic>;
    } catch (e) {
      if (!hasKeysFile) rethrow;
    }

    final balance = EVMChainERC20Balance.fromJSON(data?['balance'] as String?) ??
        EVMChainERC20Balance(BigInt.zero);

    final WalletKeysData keysData;
    // Migrate wallet from the old scheme to the new .keys file scheme
    if (!hasKeysFile) {
      final mnemonic = data!['mnemonic'] as String?;
      final privateKey = data['private_key'] as String?;
      final passphrase = data['passphrase'] as String?;

      keysData = WalletKeysData(
        mnemonic: mnemonic,
        privateKey: privateKey,
        passphrase: passphrase,
      );
    } else {
      keysData = await WalletKeysFile.readKeysFile(
        name,
        walletInfo.type,
        password,
        encryptionFileUtils,
      );
    }

    final savedChainId = data?['selected_chain_id'] as int?;

    final registry = EvmChainRegistry();

    // For old wallet types (base, ethereum, polygon, arbitrum), always default to their
    // wallet type's chainId when opening, ignoring any saved chainId.
    // Users can then switch chains if desired.
    // For WalletType.evm, use saved chainId or default to Ethereum (1)
    final chainId = walletInfo.type == WalletType.evm
        ? (savedChainId ?? 1)
        : registry.getChainConfigByWalletType(walletInfo.type)?.chainId;

    if (chainId == null) {
      throw Exception('Chain config not found for wallet type: ${walletInfo.type}');
    }

    final chainConfig = registry.getChainConfig(chainId);
    if (chainConfig == null) {
      throw Exception('Chain config not found for chainId: $chainId');
    }

    final client = EVMChainClientFactory.createClient(chainId);

    // For old wallet types, always use the wallet type's chainId as initialChainId
    // (ignoring savedChainId to ensure they default to their specific chain)
    // For WalletType.evm, use savedChainId if available, otherwise the computed chainId
    final initialChainIdForWallet =
        walletInfo.type == WalletType.evm ? (savedChainId ?? chainId) : chainId;

    return EVMChainWallet(
      walletInfo: walletInfo,
      derivationInfo: await walletInfo.getDerivationInfo(),
      password: password,
      mnemonic: keysData.mnemonic,
      privateKey: keysData.privateKey,
      passphrase: keysData.passphrase,
      initialBalance: balance,
      client: client,
      nativeCurrency: chainConfig.nativeCurrency,
      encryptionFileUtils: encryptionFileUtils,
      initialChainId: initialChainIdForWallet,
    );
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
  ///
  /// ArbiScan for Arbitrum.
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
