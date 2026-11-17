part of "app_backup_bloc.dart";

const _unchanged = Object();

@immutable
final class AppBackupConfig {
  const AppBackupConfig({
    this.wallets = const [],
    this.excludedWalletIds = const {},
    this.walletSizes = const {},
    this.sharedSize,
    this.password = "",
    this.storages = const [AppBackupStorage.custom],
    this.preferredStorage = AppBackupStorage.custom,
    this.lastBackup,
    this.isSetupCompleted = false,
  });

  final List<WalletInfo> wallets;
  final Set<String> excludedWalletIds;
  final Map<String, int> walletSizes;
  final int? sharedSize;
  final String password;
  final List<AppBackupStorage> storages;
  final AppBackupStorage preferredStorage;
  final AppBackupRecord? lastBackup;
  final bool isSetupCompleted;

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

  AppBackupConfig copyWith({
    List<WalletInfo>? wallets,
    Set<String>? excludedWalletIds,
    Map<String, int>? walletSizes,
    Object? sharedSize = _unchanged,
    String? password,
    List<AppBackupStorage>? storages,
    AppBackupStorage? preferredStorage,
    Object? lastBackup = _unchanged,
    bool? isSetupCompleted,
  }) =>
      AppBackupConfig(
        wallets: wallets ?? this.wallets,
        excludedWalletIds: excludedWalletIds ?? this.excludedWalletIds,
        walletSizes: walletSizes ?? this.walletSizes,
        sharedSize: sharedSize == _unchanged ? this.sharedSize : sharedSize as int?,
        password: password ?? this.password,
        storages: storages ?? this.storages,
        preferredStorage: preferredStorage ?? this.preferredStorage,
        lastBackup: lastBackup == _unchanged ? this.lastBackup : lastBackup as AppBackupRecord?,
        isSetupCompleted: isSetupCompleted ?? this.isSetupCompleted,
      );
}

@immutable
sealed class AppBackupState {
  const AppBackupState();

  AppBackupConfig get config;

  bool get isBusy => this is AppBackupCreating || this is AppBackupSaving;
}

final class AppBackupLoading extends AppBackupState {
  const AppBackupLoading();

  @override
  AppBackupConfig get config => const AppBackupConfig();
}

sealed class AppBackupLoaded extends AppBackupState {
  const AppBackupLoaded(this.config);

  @override
  final AppBackupConfig config;

  AppBackupLoaded withConfig(AppBackupConfig config);
}

final class AppBackupIdle extends AppBackupLoaded {
  const AppBackupIdle(super.config);

  @override
  AppBackupIdle withConfig(AppBackupConfig config) => AppBackupIdle(config);
}

final class AppBackupVerifying extends AppBackupLoaded {
  const AppBackupVerifying(
    super.config, {
    this.input = "",
    this.showMismatch = false,
    this.newPassword,
  });

  final String input;
  final bool showMismatch;
  final String? newPassword;

  String get passwordToVerify => newPassword ?? config.password;

  bool get passwordMatches => passwordToVerify.isNotEmpty && input.trim() == passwordToVerify;

  bool get canSubmit => input.trim().isNotEmpty && !showMismatch;

  AppBackupVerifying copyWith({String? input, bool? showMismatch}) => AppBackupVerifying(
        config,
        input: input ?? this.input,
        showMismatch: showMismatch ?? this.showMismatch,
        newPassword: newPassword,
      );

  @override
  AppBackupVerifying withConfig(AppBackupConfig config) => AppBackupVerifying(
        config,
        input: input,
        showMismatch: showMismatch,
        newPassword: newPassword,
      );
}

final class AppBackupCreating extends AppBackupLoaded {
  const AppBackupCreating(super.config, {required this.returnTo});

  final AppBackupLoaded returnTo;

  @override
  AppBackupCreating withConfig(AppBackupConfig config) =>
      AppBackupCreating(config, returnTo: returnTo);
}

final class AppBackupReadyToSave extends AppBackupLoaded {
  const AppBackupReadyToSave(super.config, {required this.file});

  final File file;

  @override
  AppBackupReadyToSave withConfig(AppBackupConfig config) =>
      AppBackupReadyToSave(config, file: file);
}

final class AppBackupSaving extends AppBackupLoaded {
  const AppBackupSaving(super.config, {required this.file, required this.returnTo});

  final File file;
  final AppBackupLoaded returnTo;

  @override
  AppBackupSaving withConfig(AppBackupConfig config) =>
      AppBackupSaving(config, file: file, returnTo: returnTo);
}
