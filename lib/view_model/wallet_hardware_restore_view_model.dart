import 'package:cake_wallet/bitcoin/bitcoin.dart';
import 'package:cake_wallet/core/generate_wallet_password.dart';
import 'package:cake_wallet/core/wallet_creation_service.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/monero/monero.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/view_model/hardware_wallet/hardware_wallet_view_model.dart';
import 'package:cake_wallet/view_model/hardware_wallet/ledger_view_model.dart';
import 'package:cake_wallet/view_model/seed_settings_view_model.dart';
import 'package:cake_wallet/view_model/wallet_creation_vm.dart';
import 'package:cw_core/hardware/hardware_account_data.dart';
import 'package:cw_core/utils/print_verbose.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/wallet_credentials.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:mobx/mobx.dart';

part 'wallet_hardware_restore_view_model.g.dart';

class WalletHardwareRestoreViewModel = WalletHardwareRestoreViewModelBase
    with _$WalletHardwareRestoreViewModel;

abstract class WalletHardwareRestoreViewModelBase extends WalletCreationVM with Store {
  final HardwareWalletViewModel hardwareWalletVM;

  int _nextIndex = 0;

  WalletHardwareRestoreViewModelBase(
      this.hardwareWalletVM,
      AppStore appStore,
      WalletCreationService walletCreationService,
      SeedSettingsViewModel seedSettingsViewModel,
      {required WalletType type})
      : super(appStore, walletCreationService, seedSettingsViewModel,
            type: type, isRecovery: true);

  @observable
  String name = "";

  @observable
  HardwareAccountData? selectedAccount = null;

  @observable
  bool isLoadingMoreAccounts = false;

  @observable
  String? error = null;

  // @observable
  ObservableList<HardwareAccountData> availableAccounts = ObservableList();

  @action
  Future<void> getNextAvailableAccounts(int limit) async {
    try {
      final service = await hardwareWalletVM.getHardwareWalletService(type);
      final accounts = await service
          .getAvailableAccounts(index: _nextIndex, limit: limit);

      availableAccounts.addAll(accounts);
      _nextIndex += limit;
    } catch (e) {
      printV(e);
      error =
          hardwareWalletVM.interpretErrorCode(e.toString()) ?? S.current.ledger_connection_error;
    }

    isLoadingMoreAccounts = false;
  }

  @override
  WalletCredentials getCredentials(dynamic _options) {
    WalletCredentials credentials;
    switch (type) {
      case WalletType.bitcoin:
      case WalletType.litecoin:
        credentials =
            bitcoin!.createBitcoinHardwareWalletCredentials(name: name, accountData: selectedAccount!);
        break;
      case WalletType.ethereum:
      case WalletType.polygon:
        credentials = evm!.createEVMHardwareWalletCredentials(
          name: name,
          hwAccountData: selectedAccount!,
        );
        break;
      case WalletType.monero:
        final password = walletPassword ?? generateWalletPassword();

        credentials = monero!.createMoneroRestoreWalletFromHardwareCredentials(
          name: name,
          ledgerConnection: (hardwareWalletVM as LedgerViewModel).connection,
          password: password,
          height: _options['height'] as int? ?? 0,
        );
      default:
        throw Exception('Unexpected type: ${type.toString()}');
    }

    credentials.hardwareWalletType = hardwareWalletVM.hardwareWalletType;

    return credentials;
  }

  @override
  Future<WalletBase> process(WalletCredentials credentials) async {
    walletCreationService.changeWalletType(type: type);
    return walletCreationService.restoreFromHardwareWallet(credentials);
  }
}
