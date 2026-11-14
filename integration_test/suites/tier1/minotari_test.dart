import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/core/new_wallet_arguments.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/minotari/minotari.dart";
import "package:cake_wallet/store/app_store.dart";
import "package:cake_wallet/view_model/restore/restore_mode.dart";
import "package:cake_wallet/view_model/wallet_creation_vm.dart";
import "package:cake_wallet/view_model/wallet_new_vm.dart";
import "package:cake_wallet/view_model/wallet_restore_view_model.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/crypto_currency.dart";
import "package:cw_core/output_info.dart";
import "package:cw_core/sync_status.dart";
import "package:cw_core/transaction_direction.dart";
import "package:cw_core/wallet_base.dart";
import "package:cw_core/wallet_service.dart";
import "package:cw_core/wallet_type.dart";
import "package:flutter_test/flutter_test.dart";
import "package:integration_test/integration_test.dart";

import "../../core/app_launcher.dart";
import "../../core/test_config.dart";
import "../../core/test_wallets.dart";

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // Mainnet against the default node. Only the spending flows need funds.
  integrationTest("Minotari wallet flows", (tester) async {
    if (minotari == null || TestWallets.seedFor(WalletType.minotari).trim().isEmpty) {
      tester.printToConsole("Minotari test wallet secrets missing, skipped");
      return;
    }

    await AppLauncher(tester).launchApp(testKey: "minotari_test_app_key");

    final appStore = getIt.get<AppStore>();
    tester.printToConsole("Create a wallet");
    final newWalletVM =
        getIt.get<WalletNewVM>(param1: NewWalletArguments(type: WalletType.minotari));
    await newWalletVM.create();
    _expectCreated(newWalletVM);
    expect(appStore.wallet!.walletInfo.network, "mainNet");

    tester.printToConsole("Restore from seed and check the receive address");
    await _restore(WalletRestoreMode.seed, {
      "name": "minotari_seed_restore",
      "seed": TestWallets.seedFor(WalletType.minotari),
    });
    expect(appStore.wallet!.walletAddresses.address,
        TestWallets.receiveAddressFor(WalletType.minotari));

    tester.printToConsole("Restore from spend and view keys");
    final restoreHeight = int.parse(TestWallets.minotariRestoreHeight);
    await _restore(WalletRestoreMode.keys, {
      "name": "minotari_keys_restore",
      "viewKey": TestWallets.minotariViewKey,
      "spendKey": TestWallets.minotariSpendKey,
      "height": restoreHeight,
    });
    final wallet = appStore.wallet!;
    expect(wallet.walletAddresses.address, TestWallets.receiveAddressFor(WalletType.minotari));
    expect(wallet.canSend(), isTrue);

    tester.printToConsole("Sign and verify a message");
    const message = "Cake Wallet Minotari integration test";
    final signature = await wallet.signMessage(message);
    expect(await wallet.verifyMessage(message, signature), isTrue);
    expect(await wallet.verifyMessage("$message!", signature), isFalse);

    tester.printToConsole("Rescan from the restore height");
    await _waitForSynced(tester, wallet);
    await wallet.rescan(height: restoreHeight);
    await _waitForSynced(tester, wallet);

    if (TestConfig.shouldSpend("minotari")) {
      final recipient = TestWallets.minotariRecipientAddress;
      OutputInfo output({BigInt? amount}) => OutputInfo(
            address: recipient,
            sendAll: amount == null,
            isParsedAddress: false,
            cryptoAmount: Money(amount ?? BigInt.zero, CryptoCurrency.xtm),
          );

      tester.printToConsole("Send to two recipients");
      await _send(wallet, [output(amount: BigInt.from(1000)), output(amount: BigInt.from(2000))]);
      expect(
        wallet.transactionHistory.transactions.values
            .any((tx) => tx.isPending && tx.direction == TransactionDirection.outgoing),
        isTrue,
      );

      tester.printToConsole("Send all");
      await _send(wallet, [output()]);
      expect(wallet.balance[CryptoCurrency.xtm]!.available.amount, BigInt.zero);
    }

    tester.printToConsole("Change the password and reopen");
    const newPassword = "minotari-integration-password";
    await wallet.changePassword(newPassword);
    await wallet.close();
    final reopened = await getIt
        .get<WalletService>(param1: WalletType.minotari)
        .openWallet(wallet.name, newPassword);
    expect(reopened.walletAddresses.address, TestWallets.receiveAddressFor(WalletType.minotari));
    await reopened.close();
  });
}

Future<void> _restore(WalletRestoreMode mode, Map<String, dynamic> options) async {
  final restoreVM = getIt.get<WalletRestoreViewModel>(param1: WalletType.minotari);
  restoreVM.mode = mode;
  await restoreVM.create(options: options);
  _expectCreated(restoreVM);
}

void _expectCreated(WalletCreationVM viewModel) {
  final state = viewModel.state;
  expect(state, isA<ExecutedSuccessfullyState>(),
      reason: state is FailureState ? state.error : "$state");
}

Future<void> _send(WalletBase wallet, List<OutputInfo> outputs) async {
  final pending =
      await wallet.createTransaction(minotari!.createMinotariTransactionCredentialsRaw(outputs));
  await pending.commit();
}

Future<void> _waitForSynced(WidgetTester tester, WalletBase wallet) async {
  final endTime = DateTime.now().add(TestConfig.walletSyncBudget);
  while (wallet.syncStatus is! SyncedSyncStatus) {
    if (DateTime.now().isAfter(endTime)) {
      throw TestFailure("Minotari never synced, its status was ${wallet.syncStatus.runtimeType}");
    }
    await tester.pump(const Duration(milliseconds: 250));
  }
}
