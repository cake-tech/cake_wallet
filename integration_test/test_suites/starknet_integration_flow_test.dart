import 'package:cake_wallet/starknet/starknet.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/output_info.dart';
import 'package:cw_core/starknet_token.dart';
import 'package:cw_starknet/starknet_client.dart';
import 'package:cw_starknet/starknet_transaction_credentials.dart';
import 'package:cw_starknet/src/rust/api/starknet.dart' as rust_api;
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '../helpers/starknet_integration_harness.dart';

const _testMnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';
const _testTypedDataJson =
    '{"types":{"Message":[{"name":"contents","type":"felt"}]},"primaryType":"Message","domain":{},"message":{"contents":"0x1"}}';
const _testTokenAddress =
    '0x0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef';
const _testRecipientAddress =
    '0x1111111111111111111111111111111111111111111111111111111111111111';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late StarknetIntegrationHarness harness;

  setUp(() async {
    harness = StarknetIntegrationHarness();
    await harness.setUp();
  });

  tearDown(() async {
    await harness.tearDown();
  });

  testWidgets('creates and syncs a Starknet wallet', (tester) async {
    final client = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
      },
    );

    final wallet = await harness.createWallet(
      client: client,
      mnemonic: _testMnemonic,
    );
    final derivedAccount = await harness.deriveAccount(
      mnemonic: _testMnemonic,
      accountClassHashHex: wallet.accountClassHashHex,
    );

    expect(wallet.accountAddress, startsWith('0x'));
    expect(wallet.publicKey, startsWith('0x'));
    expect(wallet.accountAddress, derivedAccount.accountAddressHex);
    expect(wallet.publicKey, derivedAccount.publicKeyHex);
    expect(
      wallet.balance[CryptoCurrency.strk]?.fullAvailableBalance,
      _strk('5'),
    );
  });

  testWidgets('handles undeployed first send', (tester) async {
    final client = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
      },
      initiallyDeployed: false,
    );

    final wallet = await harness.createWallet(
      client: client,
      mnemonic: _testMnemonic,
    );

    final pending = await wallet.createTransaction(
      StarknetTransactionCredentials(
        const [
          OutputInfo(
            address: _testRecipientAddress,
            sendAll: false,
            isParsedAddress: false,
            cryptoAmount: '2',
          ),
        ],
        currency: CryptoCurrency.strk,
      ),
    );

    await pending.commit();
    await wallet.updateBalance();
    await wallet.updateTransactionsHistory();

    expect(client.lastExecutionRequiredDeployment, isTrue);
    expect(pending.id, isNotEmpty);
    expect(
      wallet.balance[CryptoCurrency.strk]?.fullAvailableBalance,
      _strk('5') - _strk('2') - BigInt.parse('10000000000000000'),
    );
    expect(
      wallet.transactionHistory.transactions.values.any(
        (tx) => tx.transactionHash == pending.id,
      ),
      isTrue,
    );
  });

  testWidgets('imports a Starknet token and sends it', (tester) async {
    final token = StarknetToken(
      name: 'Integration Token',
      symbol: 'ITK',
      contractAddress: _testTokenAddress,
      decimal: 6,
    );

    final client = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
        _testTokenAddress.toLowerCase(): BigInt.from(100000000),
      },
      tokenMetadataByAddress: {
        _testTokenAddress.toLowerCase(): rust_api.StarknetTokenMetadata(
          tokenAddressHex: _testTokenAddress.toLowerCase(),
          name: token.name,
          symbol: token.symbol,
          decimals: token.decimal,
        ),
      },
    );

    final wallet = await harness.createWallet(
      client: client,
      mnemonic: _testMnemonic,
    );
    await wallet.addStarknetToken(token);
    await wallet.updateBalance();

    final pending = await wallet.createTransaction(
      StarknetTransactionCredentials(
        const [
          OutputInfo(
            address: _testRecipientAddress,
            sendAll: false,
            isParsedAddress: false,
            cryptoAmount: '25',
          ),
        ],
        currency: token,
      ),
    );

    await pending.commit();
    await wallet.updateBalance();
    await wallet.updateTransactionsHistory();

    expect(wallet.balance[token]?.fullAvailableBalance, BigInt.from(75000000));
    expect(
      wallet.transactionHistory.transactions.values.any(
        (tx) =>
            tx.tokenAddress.toLowerCase() == _testTokenAddress.toLowerCase(),
      ),
      isTrue,
    );
  });

  testWidgets('handles Ledger restore and send', (tester) async {
    final baseClient = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
      },
    );
    final baseWallet = await harness.createWallet(
      client: baseClient,
      mnemonic: _testMnemonic,
    );
    final baseAccount = await harness.deriveAccount(
      mnemonic: _testMnemonic,
      accountClassHashHex: baseWallet.accountClassHashHex,
    );

    final ledgerClient = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
      },
    );
    final hardwareAccount = HardwareAccountData(
      address: baseWallet.accountAddress,
      accountIndex: 0,
      derivationPath: "m/44'/9004'/0'/0/0",
      publicKey: baseWallet.publicKey,
    );
    final hardwareService = TestHardwareWalletService(
      privateKeyHex: baseAccount.privateKeyHex,
      accountData: hardwareAccount,
    );

    final ledgerWallet = await harness.restoreLedgerWallet(
      client: ledgerClient,
      accountData: hardwareAccount,
      accountClassHashHex: baseWallet.accountClassHashHex,
      hardwareWalletService: hardwareService,
    );

    final pending = await ledgerWallet.createTransaction(
      StarknetTransactionCredentials(
        const [
          OutputInfo(
            address: _testRecipientAddress,
            sendAll: false,
            isParsedAddress: false,
            cryptoAmount: '1',
          ),
        ],
        currency: CryptoCurrency.strk,
      ),
    );

    await pending.commit();

    expect(hardwareService.signCount, greaterThan(0));
    expect(pending.id, isNotEmpty);
  });

  testWidgets('handles air-gapped Starknet UR round-trip', (tester) async {
    final baseClient = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
      },
    );
    final baseWallet = await harness.createWallet(
      client: baseClient,
      mnemonic: _testMnemonic,
    );
    final baseAccount = await harness.deriveAccount(
      mnemonic: _testMnemonic,
      accountClassHashHex: baseWallet.accountClassHashHex,
    );

    final offlineClient = FakeStarknetWalletClient(
      initialBalancesByToken: {
        StarknetTokenAddresses.strk.toLowerCase(): _strk('5'),
      },
      initiallyDeployed: false,
    );
    final offlineWallet = await harness.restoreWalletFromPublicKey(
      client: offlineClient,
      publicKeyHex: baseWallet.publicKey,
      accountClassHashHex: baseWallet.accountClassHashHex,
    );

    final messageRequest = await starknet!.buildMessageSignUr(
      offlineWallet,
      'integration-message',
    );
    final messageResponse = await harness.signMessageRequestUr(
      privateKeyHex: baseAccount.privateKeyHex,
      requestUr: messageRequest.values.first,
    );
    final signedMessage = await starknet!.commitMessageUR(
      offlineWallet,
      messageResponse,
    );
    expect(signedMessage.split(','), hasLength(2));

    final typedDataRequest = await starknet!.buildTypedDataSignUr(
      offlineWallet,
      _testTypedDataJson,
    );
    final typedDataResponse = await harness.signTypedDataRequestUr(
      privateKeyHex: baseAccount.privateKeyHex,
      requestUr: typedDataRequest.values.first,
    );
    final typedDataSignature = await starknet!.commitTypedDataUR(
      offlineWallet,
      typedDataResponse,
    );
    expect(typedDataSignature, hasLength(2));

    final pending = await offlineWallet.createTransaction(
      StarknetTransactionCredentials(
        const [
          OutputInfo(
            address: _testRecipientAddress,
            sendAll: false,
            isParsedAddress: false,
            cryptoAmount: '1',
          ),
        ],
        currency: CryptoCurrency.strk,
      ),
    );
    expect(pending.shouldCommitUR(), isTrue);

    final transactionRequest = await pending.commitUR();
    final transactionResponse = await harness.signTransactionRequestUr(
      privateKeyHex: baseAccount.privateKeyHex,
      requestUr: transactionRequest.values.first,
    );
    final txHash = await starknet!.commitTransactionUR(
      offlineWallet,
      transactionResponse,
      requestUr: transactionRequest.values.first,
    );

    expect(txHash, isNotEmpty);
  });
}

BigInt _strk(String amount) {
  final parts = amount.split('.');
  final whole = BigInt.parse(parts.first) * BigInt.from(10).pow(18);
  if (parts.length == 1) {
    return whole;
  }

  final fraction = parts[1].padRight(18, '0').substring(0, 18);
  return whole + BigInt.parse(fraction);
}
