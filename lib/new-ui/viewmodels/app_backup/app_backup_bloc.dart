import "dart:io";

import "package:bloc/bloc.dart";
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

part "app_backup_state.dart";

class AppBackupBloc extends Bloc<AppBackupEvent, AppBackupState> {
  AppBackupBloc(
    this._backupService,
    this._preferences,
    this._storageService,
    this._contents,
    this._secureStorage,
  ) : super(const AppBackupState()) {
    on<_Init>(_onLoad);
    on<AppBackupRefreshed>(_onLoad);
    on<_WalletSizeCalculated>(
      (event, emit) => emit(
        state.copyWith(walletSizes: {...state.walletSizes, event.walletId: event.sizeInBytes}),
      ),
    );
    on<_SharedSizeCalculated>((event, emit) => emit(state.copyWith(sharedSize: event.sizeInBytes)));
    on<WalletToggled>(
      (event, emit) => _updateExclusions(
        emit,
        state.excludedWalletIds.contains(event.walletId)
            ? ({...state.excludedWalletIds}..remove(event.walletId))
            : {...state.excludedWalletIds, event.walletId},
      ),
    );
    on<AllWalletsSelected>((event, emit) => _updateExclusions(emit, {}));
    on<AllWalletsDeselected>(
      (event, emit) => _updateExclusions(emit, state.wallets.map((info) => info.id).toSet()),
    );
    on<VerificationChanged>(
      (event, emit) => emit(state.copyWith(verificationInput: event.input, showMismatch: false)),
    );
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

  Future<void> _onLoad(AppBackupEvent event, Emitter<AppBackupState> emit) async {
    if (state.isBusy) return;

    final wallets = await WalletInfo.getAll();
    final storages = await _storageService.availableStorages();
    final preferred = _preferences.preferredStorage;
    emit(
      state.copyWith(
        status: state.status == AppBackupStatus.loading ? AppBackupStatus.idle : null,
        wallets: wallets,
        excludedWalletIds: await _contents.excludedWalletIds(),
        password: await _readPassword(),
        storages: storages,
        preferredStorage:
            preferred != null && storages.contains(preferred) ? preferred : storages.first,
        lastBackup: _preferences.lastBackup,
        isSetupCompleted: _preferences.isSetupCompleted,
      ),
    );

    _contents.sharedSize().then((size) {
      if (!isClosed) add(_SharedSizeCalculated(size));
    });
    for (final info in wallets.where((info) => !state.walletSizes.containsKey(info.id))) {
      _contents.walletSize(info).then((size) {
        if (!isClosed) add(_WalletSizeCalculated(info.id, size));
      });
    }
  }

  Future<void> _updateExclusions(Emitter<AppBackupState> emit, Set<String> walletIds) async {
    if (state.isBusy) return;

    emit(state.copyWith(excludedWalletIds: walletIds));
    if (state.canContinue) {
      await _preferences.setExcludedWalletIds(walletIds);
    }
  }

  Future<void> _onVerificationSubmitted(
    VerificationSubmitted event,
    Emitter<AppBackupState> emit,
  ) async {
    if (state.isBusy || !state.canSubmitVerification) return;

    if (!state.passwordMatches) {
      emit(state.copyWith(showMismatch: true));
      return;
    }

    final pendingPassword = state.pendingPassword;
    if (pendingPassword != null) {
      await saveBackupPassword(_secureStorage, pendingPassword);
      emit(state.copyWith(password: pendingPassword, pendingPassword: null));
      return;
    }

    final file = await _create(emit);
    if (file != null) {
      emit(state.copyWith(status: AppBackupStatus.readyToSave, backupFile: file));
    }
  }

  Future<void> _onPasswordRegenerationRequested(
    PasswordRegenerationRequested event,
    Emitter<AppBackupState> emit,
  ) async {
    if (state.isBusy) return;

    emit(
      state.copyWith(
        pendingPassword: await generateWordPassword(),
        verificationInput: "",
        showMismatch: false,
      ),
    );
  }

  Future<void> _onSaveRequested(SaveRequested event, Emitter<AppBackupState> emit) async {
    final file = state.backupFile;
    if (file == null || state.status != AppBackupStatus.readyToSave) return;

    await _save(emit, file, event.storage, onCancel: AppBackupStatus.readyToSave);
  }

  Future<void> _onPreferredStorageChanged(
    PreferredStorageChanged event,
    Emitter<AppBackupState> emit,
  ) async {
    if (state.isBusy) return;

    await _preferences.setPreferredStorage(event.storage);
    emit(state.copyWith(preferredStorage: event.storage));
  }

  Future<void> _onBackupNowRequested(
    BackupNowRequested event,
    Emitter<AppBackupState> emit,
  ) async {
    if (state.isBusy || !state.canContinue) return;

    final file = await _create(emit);
    if (file == null) return;

    emit(state.copyWith(backupFile: file));
    await _save(emit, file, state.preferredStorage, onCancel: AppBackupStatus.idle);
    if (state.status != AppBackupStatus.saved) {
      _delete(file);
      emit(state.copyWith(backupFile: null));
    }
  }

  Future<File?> _create(Emitter<AppBackupState> emit) async {
    emit(state.copyWith(status: AppBackupStatus.creating, error: null));
    try {
      await _storageService.clearOutputs();
      return await _backupService.exportBackupFile(
        state.password,
        excludedWalletIds: state.excludedWalletIds,
        outputPath: await _storageService.newBackupPath(),
      );
    } catch (e, stackTrace) {
      printV("App backup creation failed: $e\n$stackTrace");
      emit(state.copyWith(status: AppBackupStatus.failed, error: e.toString()));
      emit(state.copyWith(status: AppBackupStatus.idle));
      return null;
    }
  }

  Future<void> _save(
    Emitter<AppBackupState> emit,
    File file,
    AppBackupStorage storage, {
    required AppBackupStatus onCancel,
  }) async {
    emit(state.copyWith(status: AppBackupStatus.saving, error: null));
    try {
      if (!await _storageService.save(file, storage)) {
        emit(state.copyWith(status: onCancel));
        return;
      }

      final record = await AppBackupRecord.forFile(file);
      await _preferences.recordBackup(record);
      await _preferences.setPreferredStorage(storage);
      await _preferences.completeSetup();
      if (!_storageService.keepsFileAfterSave(storage)) {
        _delete(file);
      }
      emit(
        state.copyWith(
          status: AppBackupStatus.saved,
          lastBackup: record,
          preferredStorage: storage,
          isSetupCompleted: true,
          backupFile: null,
        ),
      );
    } catch (e, stackTrace) {
      printV("App backup save failed: $e\n$stackTrace");
      emit(state.copyWith(status: AppBackupStatus.failed, error: e.toString()));
      emit(state.copyWith(status: onCancel));
    }
  }

  void _delete(File file) {
    if (file.existsSync()) {
      file.deleteSync();
    }
  }

  @override
  Future<void> close() async {
    final file = state.backupFile;
    if (file != null) {
      _delete(file);
    }
    return super.close();
  }
}
