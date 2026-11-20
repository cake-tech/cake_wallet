import "package:cake_wallet/bitcoin/bitcoin.dart";
import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cw_core/amount/money.dart";
import "package:cw_core/pending_transaction.dart";
import "package:cw_core/wallet_base.dart";
import "package:mobx/mobx.dart";

part "derivation_recovery_view_model.g.dart";

class DerivationRecoveryViewModel = DerivationRecoveryViewModelBase
    with _$DerivationRecoveryViewModel;

/// Finds funds the wallet can't reach on other derivation paths and moves them into it. Nothing
/// runs until the user starts a scan.
abstract class DerivationRecoveryViewModelBase with Store {
  DerivationRecoveryViewModelBase(this._settingsStore, this.wallet);

  final SettingsStore _settingsStore;
  final WalletBase wallet;

  @observable
  ExecutionState state = InitialExecutionState();

  @observable
  int checkedAddresses = 0;

  @observable
  DerivationRecoveryScan? scan;

  @observable
  PendingTransaction? pendingSweep;

  @computed
  bool get isBusy => state is IsExecutingState;

  @computed
  bool get hasFundsToMove => (scan?.total ?? 0) > 0;

  String formatAmount(int amount) =>
      Money.fromInt(amount, wallet.currency).toStringWithSymbol();

  @action
  Future<void> startScan() async {
    state = IsExecutingState();
    checkedAddresses = 0;
    scan = null;
    pendingSweep = null;

    try {
      scan = await bitcoin!.scanForFundsOnOtherDerivations(
        wallet,
        onProgress: (checked) => checkedAddresses = checked,
      );
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> createSweep() async {
    final currentScan = scan;
    if (currentScan == null) {
      return;
    }

    state = IsExecutingState();
    pendingSweep = null;

    try {
      final priority =
          _settingsStore.priority[wallet.type] ?? bitcoin!.getMediumTransactionPriority();
      pendingSweep = await bitcoin!.createDerivationRecoverySweep(wallet, currentScan, priority);
      state = InitialExecutionState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }

  @action
  Future<void> commitSweep() async {
    final sweep = pendingSweep;
    if (sweep == null) {
      return;
    }

    state = IsExecutingState();

    try {
      await sweep.commit();
      pendingSweep = null;
      scan = null;
      state = ExecutedSuccessfullyState();
    } catch (e) {
      state = FailureState(e.toString());
    }
  }
}
