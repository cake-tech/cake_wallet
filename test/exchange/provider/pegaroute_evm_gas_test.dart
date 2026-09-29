// Real gas/fee/balance construction with a synthetic envelope-returning signer
// stub. No signing operation or network broadcast is performed.
// ignore_for_file: cw_custom_lints/no_restricted_imports_in_lib
import 'dart:typed_data';

import 'package:cake_wallet/exchange/provider/pegaroute/pegaroute_native_eth.dart';
import '../fixtures/synthetic_evm.dart';
import 'package:cw_core/amount/money.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/encryption_file_utils.dart';
import 'package:cw_core/erc20_token.dart';
import 'package:cw_core/evm_call_data_transaction_credentials.dart';
import 'package:cw_core/exceptions.dart';
import 'package:cw_core/wallet_addresses.dart';
import 'package:cw_core/wallet_info.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:cw_evm/clients/evm_chain_client.dart';
import 'package:cw_evm/evm_chain_transaction_history.dart';
import 'package:cw_evm/evm_chain_transaction_priority.dart';
import 'package:cw_evm/evm_chain_wallet.dart';
import 'package:cw_evm/evm_erc20_balance.dart';
import 'package:cw_evm/pending_evm_chain_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:web3dart/crypto.dart';
import 'package:web3dart/crypto.dart' as crypto;
import 'package:web3dart/web3dart.dart';

final _key = EthPrivateKey.fromInt(BigInt.one); // Public synthetic key.
const _to = '0x0000000000000000000000000000000000000001';
const _spender = '0x0000000000000000000000000000000000000002';
final _approvalToken =
    Erc20Token(name: 'USD Coin', symbol: 'USDC', contractAddress: _to, decimal: 6, chainId: 1);

class _Encryption extends Mock implements EncryptionFileUtils {}

class _History extends Mock implements EVMChainTransactionHistory {}

class _Addresses extends Mock implements WalletAddresses {}

class _Info extends Mock implements WalletInfo {}

WalletInfo _info() {
  final info = _Info();
  when(() => info.id).thenReturn('gas-fixture');
  when(() => info.name).thenReturn('gas-fixture');
  when(() => info.type).thenReturn(WalletType.ethereum);
  when(() => info.address).thenReturn(_key.address.hex);
  when(() => info.getUsedAddresses()).thenAnswer((_) async => {});
  when(() => info.getHiddenAddresses()).thenAnswer((_) async => {});
  when(() => info.getManualAddresses()).thenAnswer((_) async => {});
  return info;
}

class _Wallet extends EVMChainWallet {
  _Wallet(_Client client)
      : super(
          walletInfo: _info(),
          derivationInfo: DerivationInfo(),
          client: client,
          nativeCurrency: CryptoCurrency.eth,
          privateKey: '1'.padLeft(64, '0'),
          password: 'offline',
          encryptionFileUtils: _Encryption(),
          initialBalance: EVMChainERC20Balance(Money.parse('1', CryptoCurrency.eth)),
        );
  @override
  Future<void> initErc20Tokens() async {}
  @override
  Future<void> save() async {}
}

class _Client implements EVMChainClient {
  int estimate = 271613;
  int gasPrice = 5000000000;
  BigInt expectedValue = BigInt.parse('1000000000000000');
  int signs = 0; // Calls to the fake signer, not cryptographic signing.
  late String fixtureSender;
  int broadcasts = 0;
  String expectedData = '12345678';
  BigInt? liveBalance;
  Object? balanceError;
  late BigInt Function() cachedBalance;
  int balanceReads = 0;
  @override
  Future<EtherAmount> getBalance(EthereumAddress address, {BlockNum? atBlock}) async {
    expect(address, _key.address);
    expect(atBlock, const BlockNum.pending());
    balanceReads++;
    if (balanceError != null) throw balanceError!;
    return EtherAmount.inWei(liveBalance ?? cachedBalance());
  }

  @override
  Uint8List hexToBytes(String value) => crypto.hexToBytes(value);
  @override
  Future<int?> getGasBaseFee() async => null;
  @override
  Future<int> getGasUnitPrice() async => gasPrice;
  @override
  Future<int> getEstimatedGasUnitsForTransaction(
      {required EthereumAddress toAddress,
      required EthereumAddress senderAddress,
      required EtherAmount value,
      String? contractAddress,
      EtherAmount? gasPrice,
      EtherAmount? maxFeePerGas,
      Uint8List? data}) async {
    expect(toAddress.hex, _to);
    expect(value.getInWei, expectedValue);
    expect(bytesToHex(data!), expectedData);
    return estimate;
  }

  @override
  Uint8List getEncodedDataForApprovalTransaction({
    required EthereumAddress contractAddress,
    required EtherAmount value,
    required EthereumAddress toAddress,
  }) {
    expect(contractAddress.hex, _to);
    expect(toAddress.hex, _spender);
    expect(value.getInWei, BigInt.from(1000000));
    return hexToBytes(expectedData);
  }

  @override
  Future<PendingEVMChainTransaction> signApprovalTransaction({
    required Credentials privateKey,
    required String spender,
    required Money amount,
    required Money gasFee,
    required int estimatedGasUnits,
    required int maxFeePerGas,
    required EVMChainTransactionPriority? priority,
    required String contractAddress,
    int? gasPrice,
    bool useBlinkProtection = true,
  }) {
    expect(spender, _spender);
    expect(amount, Money.parse('1', _approvalToken));
    expect(contractAddress, _to);
    return signTransaction(
        privateKey: privateKey,
        toAddress: contractAddress,
        amount: Money.zero(CryptoCurrency.eth),
        gasFee: gasFee,
        estimatedGasUnits: estimatedGasUnits,
        maxFeePerGas: maxFeePerGas,
        priority: priority,
        currency: CryptoCurrency.eth,
        feeCurrency: 'ETH',
        data: expectedData,
        gasPrice: gasPrice,
        useBlinkProtection: useBlinkProtection);
  }

  @override
  Future<PendingEVMChainTransaction> signTransaction(
      {required Credentials privateKey,
      required String toAddress,
      required Money amount,
      required Money gasFee,
      required int estimatedGasUnits,
      required int maxFeePerGas,
      required EVMChainTransactionPriority? priority,
      required CryptoCurrency currency,
      required String feeCurrency,
      String? contractAddress,
      String? data,
      int? gasPrice,
      bool useBlinkProtection = true}) async {
    signs++;
    expect(useBlinkProtection, false);
    expect(gasFee.amount, BigInt.from(estimatedGasUnits) * BigInt.from(maxFeePerGas));
    final envelope = syntheticEvmEnvelope(to: toAddress, value: amount.amount,
        data: data == null ? '0x' : data.startsWith('0x') ? data : '0x$data',
        gas: estimatedGasUnits, gasPrice: maxFeePerGas);
    fixtureSender = envelope.sender;
    return PendingEVMChainTransaction(
        signedTransaction: hexToBytes(envelope.hex),
        amount: amount,
        fee: gasFee,
        sendTransaction: () async {
          broadcasts++;
        });
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Client client;
  late _Wallet wallet;
  setUp(() async {
    SharedPreferences.setMockInitialValues({'evm_scam_check_v2_done_gas-fixture': true});
    client = _Client();
    wallet = _Wallet(client);
    client.cachedBalance = () => wallet.balance[CryptoCurrency.eth]!.available.amount;
    final history = _History();
    when(() => history.init()).thenAnswer((_) async {});
    wallet.transactionHistory = history;
    final addresses = _Addresses();
    when(() => addresses.init()).thenAnswer((_) async {});
    wallet.walletAddresses = addresses;
    await wallet.init();
  });
  EvmCallDataTransactionCredentials credentials(int gas) => EvmCallDataTransactionCredentials(
      to: _to,
      data: '0x12345678',
      value: Money.parse('0.001', CryptoCurrency.eth),
      priority: null,
      gasLimit: gas,
      useBlinkProtection: false);
  test('existing no-supplied-gas raw-call entry point remains usable', () async {
    client.estimate = 100000;
    final pending = await wallet.createCallDataTransaction(_to, '0x12345678',
        Money.parse('0.001', CryptoCurrency.eth), EVMChainTransactionPriority.medium,
        null, null, useBlinkProtection: false);
    expect(client.signs, 1);
    expect(client.broadcasts, 0);
    expect(pending.fee.amount, BigInt.from(100000) * BigInt.from(7000000000));
  });

  for (final conflicting in ['network', 'duplicate']) {
    test('supplied token call rejects conflicting $conflicting balance entries', () async {
      client.expectedValue = BigInt.zero;
      client.expectedData = '1234';
      const tokenContract = '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa';
      final foreign = Erc20Token(name: 'Alias', symbol: 'ALIAS',
          contractAddress: conflicting == 'duplicate' ? '0x${'A' * 40}' : tokenContract,
          decimal: 6, chainId: conflicting == 'network' ? 56 : 1);
      wallet.balance[foreign] = EVMChainERC20Balance(Money.parse('10', foreign));
      if (conflicting == 'duplicate') {
        final token = Erc20Token(name: 'Token', symbol: 'TOKEN', contractAddress: tokenContract,
            decimal: 6, chainId: 1);
        wallet.balance[token] = EVMChainERC20Balance(Money.parse('10', token));
      }
      await expectLater(wallet.createTransaction(EvmCallDataTransactionCredentials(
          to: _to, data: '0x1234', value: Money.zero(CryptoCurrency.eth), gasLimit: 65000,
          priority: EVMChainTransactionPriority.medium, useBlinkProtection: false,
          sourceTokenAddress: tokenContract, sourceTokenAmount: BigInt.one)),
          conflicting == 'duplicate' ? throwsStateError : throwsA(isA<Exception>()
              .having((error) => error.toString(), 'reason', contains('Token not found'))));
      expect(client.signs, 0);
    });
  }

  // Pegaroute approves the reviewed contract through raw-call credentials, not
  // the legacy symbol-based createApprovalTransaction entry point.
  EvmCallDataTransactionCredentials approvalCredentials() => EvmCallDataTransactionCredentials(
      to: _to, data: '0x${client.expectedData}', value: Money.zero(CryptoCurrency.eth),
      priority: EVMChainTransactionPriority.medium, gasLimit: 65000, useBlinkProtection: false);
  for (final estimate in [271613, 400000, 0]) {
    test('estimate $estimate uses the supplied floor for signed gas and confirmation fee',
        () async {
      client.estimate = estimate;
      final pending = await wallet.createTransaction(credentials(351834));
      final evidence = inspectPegarouteEvm(pending.hex, chainId: 1, sender: client.fixtureSender);
      final expected = estimate > 351834 ? estimate : 351834;
      expect(evidence.gasLimit, '$expected');
      expect(pending.fee.amount, BigInt.from(expected) * BigInt.from(client.gasPrice));
      expect(client.broadcasts, 0);
    });
  }
  test('token swap checks the post-approval node balance instead of its cached balance', () async {
    wallet.balance[CryptoCurrency.eth] =
        EVMChainERC20Balance(Money.parse('0.000836033134785206', CryptoCurrency.eth));
    wallet.balance[_approvalToken] = EVMChainERC20Balance(Money.parse('5', _approvalToken));
    client.liveBalance = BigInt.parse('717351881928726');
    client.estimate = 300000;
    client.gasPrice = 2500000000;
    client.expectedValue = BigInt.zero;
    await expectLater(
        wallet.createTransaction(EvmCallDataTransactionCredentials(
            to: _to,
            data: '0x12345678',
            value: Money.zero(CryptoCurrency.eth),
            priority: null,
            gasLimit: 260662,
            sourceTokenAddress: _approvalToken.contractAddress,
            sourceTokenAmount: BigInt.from(5000000),
            useBlinkProtection: false)),
        throwsA(isA<TransactionWrongBalanceException>()
            .having((error) => error.currency, 'native gas currency', CryptoCurrency.eth)
            .having((error) => error.availableBalance!.amount, 'post-approval funds',
                BigInt.parse('717351881928726'))
            .having((error) => error.requiredBalance, 'signed gas budget',
                Money.parse('0.00075', CryptoCurrency.eth))));
    expect(client.balanceReads, 1);
    expect(client.signs, 0);
    expect(client.broadcasts, 0);
  });
  for (final approval in [false, true]) {
    test('${approval ? "approval" : "call"} stops when current node balance is unavailable',
        () async {
      client.balanceError = StateError('node balance unavailable');
      wallet.balance[_approvalToken] = EVMChainERC20Balance(Money.parse('1', _approvalToken));
      if (approval) client.expectedValue = BigInt.zero;
      final result = approval
          ? wallet.createTransaction(approvalCredentials())
          : wallet.createTransaction(credentials(351834));
      await expectLater(result, throwsA(same(client.balanceError)));
      expect(client.signs, 0);
      expect(client.broadcasts, 0);
    });
  }
  for (final estimate in [0, 40000, 80000]) {
    for (final affordable in [false, true]) {
      test('approval estimate $estimate ${affordable ? "fits" : "exceeds"} native gas balance',
          () async {
        client.estimate = estimate;
        client.expectedValue = BigInt.zero;
        client.expectedData = '095ea7b3${_spender.substring(2).padLeft(64, '0')}'
            '${BigInt.from(1000000).toRadixString(16).padLeft(64, '0')}';
        wallet.balance[_approvalToken] = EVMChainERC20Balance(Money.parse('1', _approvalToken));
        final units = estimate < 65000 ? 65000 : estimate;
        // The node has no base-fee sample, so Cake adds the selected 2-gwei tip
        // to its 5-gwei price for the existing maximum-fee calculation.
        final fee = Money(BigInt.from(units) * BigInt.from(7000000000), CryptoCurrency.eth);
        final available = affordable ? fee : fee - Money.fromInt(1, CryptoCurrency.eth);
        wallet.balance[CryptoCurrency.eth] = EVMChainERC20Balance(available);
        final result = wallet.createTransaction(approvalCredentials());
        if (affordable) {
          final pending = await result;
          expect(pending.fee, fee);
          expect(client.signs, 1);
        } else {
          await expectLater(
              result,
              throwsA(isA<TransactionWrongBalanceException>()
                  .having((error) => error.currency, 'gas currency', CryptoCurrency.eth)
                  .having((error) => error.fee, 'approval gas budget', fee)
                  .having((error) => error.requiredBalance, 'native-only requirement', fee)
                  .having((error) => error.availableBalance, 'available gas balance', available)
                  .having((error) => error.feePriority, 'priced priority',
                      EVMChainTransactionPriority.medium)));
          expect(client.signs, 0);
        }
        expect(client.broadcasts, 0);
      });
    }
  }
  for (final balance in ['0.000836033134785206', '0.0025']) {
    test('balance $balance reports insufficient ETH before signing', () async {
      // The first cannot cover the principal. The second covers the smaller
      // estimate but not the provider's larger gas limit.
      wallet.balance[CryptoCurrency.eth] =
          EVMChainERC20Balance(Money.parse(balance, CryptoCurrency.eth));
      await expectLater(
          wallet.createTransaction(credentials(351834)),
          throwsA(isA<TransactionWrongBalanceException>()
              .having((error) => error.currency, 'currency', CryptoCurrency.eth)
              .having((error) => error.requiredBalance, 'principal plus gas budget',
                  Money.parse('0.00275917', CryptoCurrency.eth))
              .having((error) => error.availableBalance, 'available balance',
                  Money.parse(balance, CryptoCurrency.eth))
              .having((error) => error.fee, 'gas budget at the supplied floor',
                  Money.parse('0.00175917', CryptoCurrency.eth))
              .having((error) => error.requiredBalance! - error.fee!, 'source value',
                  Money.parse('0.001', CryptoCurrency.eth))
              .having((error) => error.amount, 'legacy amount', isNull)));
      expect(client.signs, 0);
      expect(client.broadcasts, 0);
    });
  }
  test('token shortage reports the source token rather than the native fee currency', () async {
    final token = Erc20Token(
        name: 'USD Coin',
        symbol: 'USDC',
        contractAddress: '0x1111111111111111111111111111111111111111',
        decimal: 6,
        chainId: 1);
    wallet.balance[token] = EVMChainERC20Balance(Money.parse('0.5', token));
    client.expectedValue = BigInt.zero;
    await expectLater(
        wallet.createTransaction(EvmCallDataTransactionCredentials(
          to: _to,
          data: '0x12345678',
          value: Money.zero(CryptoCurrency.eth),
          priority: null,
          gasLimit: 351834,
          sourceTokenAddress: token.contractAddress,
          sourceTokenAmount: BigInt.from(1000000),
          useBlinkProtection: false,
        )),
        throwsA(isA<TransactionWrongBalanceException>()
            .having((error) => error.currency, 'currency', same(token))
            .having((error) => error.requiredBalance, 'token principal', Money.parse('1', token))
            .having((error) => error.availableBalance, 'token balance', Money.parse('0.5', token))
            .having((error) => error.fee, 'no native fee included in the token total', isNull)));
    expect(client.signs, 0);
    expect(client.broadcasts, 0);
  });
  test('token swap with enough tokens reports only its native gas funding shortage', () async {
    final token = Erc20Token(
        name: 'USD Coin',
        symbol: 'USDC',
        contractAddress: '0x1111111111111111111111111111111111111111',
        decimal: 6,
        chainId: 1);
    wallet.balance[token] = EVMChainERC20Balance(Money.parse('1', token));
    wallet.balance[CryptoCurrency.eth] =
        EVMChainERC20Balance(Money.parse('0.000836033134785206', CryptoCurrency.eth));
    client.expectedValue = BigInt.zero;
    await expectLater(
        wallet.createTransaction(EvmCallDataTransactionCredentials(
          to: _to,
          data: '0x12345678',
          value: Money.zero(CryptoCurrency.eth),
          priority: null,
          gasLimit: 351834,
          sourceTokenAddress: token.contractAddress,
          sourceTokenAmount: BigInt.from(1000000),
          useBlinkProtection: false,
        )),
        throwsA(isA<TransactionWrongBalanceException>()
            .having((error) => error.currency, 'shortage currency', CryptoCurrency.eth)
            .having((error) => error.requiredBalance, 'native gas only',
                Money.parse('0.00175917', CryptoCurrency.eth))
            .having((error) => error.availableBalance, 'native balance',
                Money.parse('0.000836033134785206', CryptoCurrency.eth))
            .having((error) => error.fee, 'native gas budget',
                Money.parse('0.00175917', CryptoCurrency.eth))));
    expect(client.signs, 0);
    expect(client.broadcasts, 0);
  });
  test('missing gas price cannot create a zero-fee confirmation with supplied gas', () async {
    client.gasPrice = 0;
    await expectLater(wallet.createTransaction(credentials(351834)), throwsException);
    expect(client.signs, 0);
  });
  test('invalid supplied gas stops before signing', () async {
    await expectLater(wallet.createTransaction(credentials(1)), throwsException);
    expect(client.signs, 0);
  });
}
