part of "app_backup_bloc.dart";

enum AppBackupStatus { loading, idle, creating, readyToSave, saving, saved, failed }

const _unchanged = Object();

@immutable
final class AppBackupState {
  const AppBackupState({
    this.status = AppBackupStatus.loading,
    this.wallets = const [],
    this.excludedWalletIds = const {},
    this.walletSizes = const {},
    this.sharedSize,
    this.password = "",
    this.pendingPassword,
    this.verificationInput = "",
    this.showMismatch = false,
    this.storages = const [AppBackupStorage.custom],
    this.preferredStorage = AppBackupStorage.custom,
    this.lastBackup,
    this.isSetupCompleted = false,
    this.backupFile,
    this.error,
  });

  final AppBackupStatus status;
  final List<WalletInfo> wallets;
  final Set<String> excludedWalletIds;
  final Map<String, int> walletSizes;
  final int? sharedSize;
  final String password;
  final String? pendingPassword;
  final String verificationInput;
  final bool showMismatch;
  final List<AppBackupStorage> storages;
  final AppBackupStorage preferredStorage;
  final AppBackupRecord? lastBackup;
  final bool isSetupCompleted;
  final File? backupFile;
  final String? error;

  bool get isBusy => status == AppBackupStatus.creating || status == AppBackupStatus.saving;

  bool isSelected(WalletInfo info) => !excludedWalletIds.contains(info.id);

  bool get canContinue => wallets.any(isSelected);

  int get selectedCount => wallets.where(isSelected).length;

  int? get totalSize {
    final selected = wallets.where(isSelected);
    if (sharedSize == null || selected.any((info) => !walletSizes.containsKey(info.id))) {
      return null;
    }
    return selected.fold<int>(sharedSize!, (total, info) => total + walletSizes[info.id]!);
  }

  String get passwordToVerify => pendingPassword ?? password;

  bool get passwordMatches =>
      passwordToVerify.isNotEmpty && verificationInput.trim() == passwordToVerify;

  bool get canSubmitVerification => verificationInput.trim().isNotEmpty && !showMismatch;

  AppBackupState copyWith({
    AppBackupStatus? status,
    List<WalletInfo>? wallets,
    Set<String>? excludedWalletIds,
    Map<String, int>? walletSizes,
    Object? sharedSize = _unchanged,
    String? password,
    Object? pendingPassword = _unchanged,
    String? verificationInput,
    bool? showMismatch,
    List<AppBackupStorage>? storages,
    AppBackupStorage? preferredStorage,
    Object? lastBackup = _unchanged,
    bool? isSetupCompleted,
    Object? backupFile = _unchanged,
    Object? error = _unchanged,
  }) =>
      AppBackupState(
        status: status ?? this.status,
        wallets: wallets ?? this.wallets,
        excludedWalletIds: excludedWalletIds ?? this.excludedWalletIds,
        walletSizes: walletSizes ?? this.walletSizes,
        sharedSize: sharedSize == _unchanged ? this.sharedSize : sharedSize as int?,
        password: password ?? this.password,
        pendingPassword:
            pendingPassword == _unchanged ? this.pendingPassword : pendingPassword as String?,
        verificationInput: verificationInput ?? this.verificationInput,
        showMismatch: showMismatch ?? this.showMismatch,
        storages: storages ?? this.storages,
        preferredStorage: preferredStorage ?? this.preferredStorage,
        lastBackup: lastBackup == _unchanged ? this.lastBackup : lastBackup as AppBackupRecord?,
        isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
        backupFile: backupFile == _unchanged ? this.backupFile : backupFile as File?,
        error: error == _unchanged ? this.error : error as String?,
      );
}
