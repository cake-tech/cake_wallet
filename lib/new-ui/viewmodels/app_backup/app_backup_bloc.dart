import "dart:io";

import "package:bloc/bloc.dart";
import "package:bloc_presentation/bloc_presentation.dart";
import "package:cake_wallet/core/backup/app_backup_contents.dart";
import "package:cake_wallet/core/backup/app_backup_preferences.dart";
import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/core/secure_storage.dart";
import "package:cake_wallet/entities/default_settings_migration.dart"
    show generateBackupPassword, saveBackupPassword;
import "package:cake_wallet/entities/secret_store_key.dart";
import "package:cw_core/generate_name.dart";
import "package:cw_core/utils/print_verbose.dart";
import "package:cw_core/wallet_info.dart";
import "package:meta/meta.dart";

part "app_backup_event.dart";

part "app_backup_presentation.dart";

part "app_backup_state.dart";

class AppBackupBloc extends Bloc<AppBackupEvent, AppBackupState>
    with BlocPresentationMixin<AppBackupState, AppBackupPresentation> {
  AppBackupBloc(
    this._backupService,
    this._preferences,
    this._storageService,
    this._contents,
    this._secureStorage,
  ) : super(const AppBackupLoading()) {
    on<_Init>(_onInit);
    on<_WalletSizeCalculated>(
      (event, emit) => _updateConfig(
        emit,
        (config) => config.copyWith(
          walletSizes: {...config.walletSizes, event.walletId: event.sizeInBytes},
        ),
      ),
    );
    on<_SharedSizeCalculated>(
      (event, emit) =>
          _updateConfig(emit, (config) => config.copyWith(sharedSize: event.sizeInBytes)),
    );
    on<WalletToggled>(
      (event, emit) => _updateExclusions(
        emit,
        state.config.excludedWalletIds.contains(event.walletId)
            ? ({...state.config.excludedWalletIds}..remove(event.walletId))
            : {...state.config.excludedWalletIds, event.walletId},
      ),
    );
    on<AllWalletsSelected>((event, emit) => _updateExclusions(emit, {}));
    on<AllWalletsDeselected>(
      (event, emit) => _updateExclusions(emit, state.config.wallets.map((info) => info.id).toSet()),
    );
    on<VerificationChanged>(_onVerificationChanged);
    on<VerificationSubmitted>(_onVerificationSubmitted);
    on<PasswordRegenerationRequested>(_onPasswordRegenerationRequested);
    on<SaveRequested>(_onSaveRequested);
    on<PreferredStorageChanged>(_onPreferredStorageChanged);
    on<BackupNowRequested>(_onBackupNowRequested);

    add(_Init());
  }

  final BackupServiceV3 _backupService;
  final AppBackupPreferences _preferences;
  final AppBackupStorageService _storageService;
  final AppBackupContents _contents;
  final SecureStorage _secureStorage;

  Future<String> _readPassword() async {
    final key = generateStoreKeyFor(key: SecretStoreKey.backupPassword);
    final password = await _secureStorage.read(key: key) ?? "";
    if (password.isNotEmpty) return password;

    await generateBackupPassword(_secureStorage);
    return await _secureStorage.read(key: key) ?? "";
  }

  Future<void> _onInit(_Init event, Emitter<AppBackupState> emit) async {
    final wallets = await WalletInfo.getAll();
    final storages = await _storageService.availableStorages();
    final preferred = _preferences.preferredStorage;
    emit(
      AppBackupIdle(
        AppBackupConfig(
          wallets: wallets,
          excludedWalletIds: await _contents.excludedWalletIds(),
          password: await _readPassword(),
          storages: storages,
          preferredStorage:
              preferred != null && storages.contains(preferred) ? preferred : storages.first,
          lastBackup: _preferences.lastBackup,
          isSetupCompleted: _preferences.isSetupCompleted,
        ),
      ),
    );

    _contents.sharedSize().then((size) {
      if (!isClosed) add(_SharedSizeCalculated(size));
    });
    for (final info in wallets) {
      _contents.walletSize(info).then((size) {
        if (!isClosed) add(_WalletSizeCalculated(info.id, size));
      });
    }
  }

  void _updateConfig(
    Emitter<AppBackupState> emit,
    AppBackupConfig Function(AppBackupConfig config) update,
  ) {
    final current = state;
    if (current is AppBackupLoaded) {
      emit(current.withConfig(update(current.config)));
    }
  }

  Future<void> _updateExclusions(Emitter<AppBackupState> emit, Set<String> walletIds) async {
    if (state is! AppBackupLoaded || state.isBusy) return;

    _updateConfig(emit, (config) => config.copyWith(excludedWalletIds: walletIds));
    if (state.config.canContinue) {
      await _preferences.setExcludedWalletIds(walletIds);
    }
  }

  void _onVerificationChanged(VerificationChanged event, Emitter<AppBackupState> emit) {
    switch (state) {
      case final AppBackupVerifying verifying:
        emit(verifying.copyWith(input: event.input, showMismatch: false));
      case AppBackupIdle(:final config):
        emit(AppBackupVerifying(config, input: event.input));
      default:
        break;
    }
  }

  Future<void> _onVerificationSubmitted(
    VerificationSubmitted event,
    Emitter<AppBackupState> emit,
  ) async {
    final verifying = state;
    if (verifying is! AppBackupVerifying || !verifying.canSubmit) return;

    if (!verifying.passwordMatches) {
      emit(verifying.copyWith(showMismatch: true));
      return;
    }

    final newPassword = verifying.newPassword;
    if (newPassword != null) {
      await saveBackupPassword(_secureStorage, newPassword);
      emit(AppBackupIdle(verifying.config.copyWith(password: newPassword)));
      emitPresentation(PasswordSaved());
      return;
    }

    final file = await _create(emit, returnTo: verifying);
    if (file != null) {
      emit(AppBackupReadyToSave(state.config, file: file));
      emitPresentation(BackupCreated());
    }
  }

  Future<void> _onPasswordRegenerationRequested(
    PasswordRegenerationRequested event,
    Emitter<AppBackupState> emit,
  ) async {
    if (state is! AppBackupLoaded || state.isBusy) return;

    emit(AppBackupVerifying(state.config, newPassword: await generateWordPassword()));
    emitPresentation(PasswordRegenerated());
  }

  Future<void> _onSaveRequested(SaveRequested event, Emitter<AppBackupState> emit) async {
    final ready = state;
    if (ready is! AppBackupReadyToSave) return;

    await _save(emit, ready.file, event.storage, returnTo: ready);
  }

  Future<void> _onPreferredStorageChanged(
    PreferredStorageChanged event,
    Emitter<AppBackupState> emit,
  ) async {
    if (state is! AppBackupLoaded || state.isBusy) return;

    await _preferences.setPreferredStorage(event.storage);
    _updateConfig(emit, (config) => config.copyWith(preferredStorage: event.storage));
  }

  Future<void> _onBackupNowRequested(
    BackupNowRequested event,
    Emitter<AppBackupState> emit,
  ) async {
    final current = state;
    if (current is! AppBackupLoaded || current.isBusy || !current.config.canContinue) return;

    final file = await _create(emit, returnTo: current);
    if (file == null) return;

    if (!await _save(emit, file, state.config.preferredStorage, returnTo: current)) {
      _delete(file);
    }
  }

  Future<File?> _create(Emitter<AppBackupState> emit, {required AppBackupLoaded returnTo}) async {
    emit(AppBackupCreating(returnTo.config, returnTo: returnTo));
    try {
      await _storageService.clearOutputs();
      return await _backupService.exportBackupFile(
        state.config.password,
        excludedWalletIds: state.config.excludedWalletIds,
        outputPath: await _storageService.newBackupPath(),
      );
    } catch (e, stackTrace) {
      printV("App backup creation failed: $e\n$stackTrace");
      emit(returnTo.withConfig(state.config));
      emitPresentation(BackupFailed(e.toString()));
      return null;
    }
  }

  Future<bool> _save(
    Emitter<AppBackupState> emit,
    File file,
    AppBackupStorage storage, {
    required AppBackupLoaded returnTo,
  }) async {
    emit(AppBackupSaving(state.config, file: file, returnTo: returnTo));
    try {
      if (!await _storageService.save(file, storage)) {
        emit(returnTo.withConfig(state.config));
        return false;
      }

      final isFirstBackup = !state.config.isSetupCompleted;
      final record = await AppBackupRecord.forFile(file);
      await _preferences.recordBackup(record);
      await _preferences.setPreferredStorage(storage);
      await _preferences.completeSetup();
      if (!_storageService.keepsFileAfterSave(storage)) {
        _delete(file);
      }
      emit(
        AppBackupIdle(
          state.config.copyWith(
            lastBackup: record,
            preferredStorage: storage,
            isSetupCompleted: true,
          ),
        ),
      );
      emitPresentation(BackupSaved(isFirstBackup: isFirstBackup));
      return true;
    } catch (e, stackTrace) {
      printV("App backup save failed: $e\n$stackTrace");
      emit(returnTo.withConfig(state.config));
      emitPresentation(BackupFailed(e.toString()));
      return false;
    }
  }

  void _delete(File file) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  @override
  Future<void> close() async {
    final file = switch (state) {
      AppBackupReadyToSave(:final file) || AppBackupSaving(:final file) => file,
      _ => null,
    };
    if (file != null) {
      _delete(file);
    }
    return super.close();
  }
}
