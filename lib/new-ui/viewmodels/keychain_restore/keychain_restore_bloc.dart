import "package:bloc/bloc.dart";
import "package:bloc_concurrency/bloc_concurrency.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/wallet_creation_service.dart";
import "package:cake_wallet/new-ui/services/wallet_switch_service.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_restore/keychain_restore_presentation_event.dart";
import "package:cake_wallet/new-ui/viewmodels/keychain_restore/keychain_restore_util.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:cw_core/wallet_type.dart";
import "package:cw_keychain/cw_keychain.dart";
import "package:meta/meta.dart";

part "keychain_restore_event.dart";

part "keychain_restore_state.dart";

class KeychainRestoreBloc extends Bloc<KeychainRestoreEvent, KeychainRestoreState>
    with BlocPresentationMixin<KeychainRestoreState, KeychainRestorePresentationEvent> {
  KeychainRestoreBloc(
      {required WalletSwitchService walletSwitchService,
      required WalletCreationService creationService,
      required CwKeychain keychain})
      : _walletSwitchService = walletSwitchService,
        _creationService = creationService,
        _keychain = keychain,
        super(const KeychainRestoreNotLoaded()) {
    on<_Init>(_init);
    on<WalletToggled>(_onWalletToggled, transformer: sequential());
    on<RestoreInitiated>(_onRestoreInitiated, transformer: droppable());
    on<WalletOpenSelected>(_onWalletOpenSelected, transformer: droppable());
    add(const _Init());
  }

  final CwKeychain _keychain;
  final WalletSwitchService _walletSwitchService;
  final WalletCreationService _creationService;

  Future<void> _init(_Init event, Emitter<KeychainRestoreState> emit) async {
    if (!(await _keychain.available())) {
      emit(const KeychainRestoreUnavailable());
      return;
    }

    final existingWalletNames = (await WalletInfo.getAll()).map((item) => item.name);
    final keychainData = (await _keychain.getAll())
        .where((item) => !existingWalletNames.contains(item.name))
        .toList();
    if (keychainData.isEmpty) {
      emit(const KeychainRestoreNoWallets());
      return;
    }

    emit(KeychainRestoreSelection(walletsAvailable: keychainData, walletsSelected: {}));
  }

  Future<void> _onWalletToggled(WalletToggled event, Emitter<KeychainRestoreState> emit) async {
    if (state case final KeychainRestoreSelection s) {
      final walletsSelected = s.walletsSelected;
      final item = s.walletsAvailable[event.index];
      if (walletsSelected.contains(item)) {
        walletsSelected.remove(item);
      } else {
        walletsSelected.add(item);
      }
      emit(s.copyWith(walletsSelected: walletsSelected));
    }
  }

  Future<void> _onRestoreInitiated(
      RestoreInitiated event, Emitter<KeychainRestoreState> emit) async {
    if (state case final KeychainRestoreSelection s) {
      KeychainRestoring restoringState = KeychainRestoring(
          walletsRestored: {},
          walletsFailed: {},
          walletsAvailable: s.walletsAvailable,
          walletsSelected: s.walletsSelected);
      emit(restoringState);
      final walletsSelected = s.walletsSelected.toList();
      final List<WalletInfo> walletInfos = [];
      for (final wallet in walletsSelected) {
        try {
          final credentials = await KeychainRestoreUtilities.credentialsFromKeychainData(wallet);
          _creationService.changeWalletType(type: deserializeFromInt(wallet.walletTypeRaw));
          final created = await _creationService.restoreFromSeed(credentials,
              isTestnet: wallet.networkRaw == 1);
          walletInfos.add(created.walletInfo);
        } catch (e, st) {
          printV("$e\n$st");
          restoringState =
              restoringState.copyWith(walletsFailed: {...restoringState.walletsFailed, wallet});
          emit(restoringState);
          continue;
        }
        restoringState =
            restoringState.copyWith(walletsRestored: {...restoringState.walletsRestored, wallet});
        emit(restoringState);
      }
      emit(KeychainRestoreComplete(
          walletInfos: walletInfos,
          walletsRestored: restoringState.walletsRestored,
          walletsFailed: restoringState.walletsFailed,
          walletsAvailable: restoringState.walletsAvailable,
          walletsSelected: restoringState.walletsSelected));
    }
  }

  Future<void> _onWalletOpenSelected(
      WalletOpenSelected event, Emitter<KeychainRestoreState> emit) async {
    if (state case final KeychainRestoreComplete s) {
      final walletData = s.walletsAvailable[event.index];
      final walletInfo = s.walletInfos.firstWhere((item) =>
          item.name == walletData.name &&
          item.type == deserializeFromInt(walletData.walletTypeRaw));
      await _walletSwitchService.switchToWallet(walletInfo);
      emitPresentation(const WalletOpened());
    }
  }
}
