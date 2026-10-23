import "dart:io";

import "package:cake_wallet/core/backup/app_backup_restorer.dart";
import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/core/backup_service_v3.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_creating_page.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup_restore/app_backup_restore_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/routes.dart";
import "package:cake_wallet/src/screens/pin_code/pin_code_widget.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/alert_with_two_actions.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/store/settings_store.dart";
import "package:cake_wallet/utils/show_pop_up.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupRestorePage extends StatefulWidget {
  const BackupRestorePage({required this.file, super.key});

  final File file;

  static Future<void> start(BuildContext context) async {
    if (!await _ensurePin(context) || !context.mounted) return;

    final file = await getIt.get<AppBackupStorageService>().pickBackupFile();
    if (file == null || !context.mounted) return;

    if (!getIt.get<AppBackupRestorer>().isBackupFile(file)) {
      await getIt.get<AppBackupStorageService>().clearPickedFiles();
      if (context.mounted) {
        await _showError(context, S.of(context).app_backup_restore_invalid_file);
      }
      return;
    }

    await Navigator.of(context)
        .push(CupertinoPageRoute<void>(builder: (_) => BackupRestorePage(file: file)));
  }

  static Future<bool> _ensurePin(BuildContext context) async {
    final restorer = getIt.get<AppBackupRestorer>();
    if (SettingsStoreBase.walletPasswordDirectInput || await restorer.hasPin()) return true;
    if (!context.mounted) return false;

    await Navigator.of(context).pushNamed(
      Routes.setupPin,
      arguments: (PinCodeState<PinCodeWidget> pinCode, String _) => pinCode.close(),
    );
    return restorer.hasPin();
  }

  static Future<void> _showError(BuildContext context, String error) => showPopUp<void>(
        context: context,
        builder: (dialogContext) => AlertWithOneAction(
          alertTitle: S.of(dialogContext).app_backup_restore_failed,
          alertContent: error,
          buttonText: S.of(dialogContext).ok,
          buttonAction: Navigator.of(dialogContext).pop,
        ),
      );

  @override
  State<BackupRestorePage> createState() => _BackupRestorePageState();
}

class _BackupRestorePageState extends State<BackupRestorePage> {
  final _controller = TextEditingController();
  Route<void>? _progressRoute;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _showProgress(BuildContext context) {
    FocusManager.instance.primaryFocus?.unfocus();
    final route = CupertinoPageRoute<void>(
      builder: (context) => BackupCreatingPage(title: S.of(context).app_backup_restoring),
    );
    _progressRoute = route;
    Navigator.of(context).push(route);
  }

  void _hideProgress(BuildContext context) {
    final route = _progressRoute;
    _progressRoute = null;
    if (route == null || !route.isActive) return;
    route.isCurrent ? Navigator.of(context).pop() : Navigator.of(context).removeRoute(route);
  }

  Future<void> _confirmAppMismatch(
    BuildContext context,
    IncompatibleBackupAppException mismatch,
  ) async {
    final confirmed = await showPopUp<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertWithTwoActions(
        alertTitle: S.of(dialogContext).warning,
        alertContent: S
            .of(dialogContext)
            .app_backup_restore_other_app(mismatch.sourceAppName, mismatch.currentAppName),
        leftButtonText: S.of(dialogContext).cancel,
        rightButtonText: S.of(dialogContext).ok,
        actionLeftButton: () => Navigator.of(dialogContext).pop(false),
        actionRightButton: () => Navigator.of(dialogContext).pop(true),
      ),
    );
    if (context.mounted) {
      context
          .read<AppBackupRestoreBloc>()
          .add(confirmed == true ? AppMismatchConfirmed() : AppMismatchDismissed());
    }
  }

  Future<void> _paste(BuildContext context) async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty || !context.mounted) return;

    _controller.text = text;
    context.read<AppBackupRestoreBloc>().add(RestorePasswordChanged(text));
  }

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt.get<AppBackupRestoreBloc>(param1: widget.file),
        child: MultiBlocListener(
          listeners: [
            BlocListener<AppBackupRestoreBloc, AppBackupRestoreState>(
              listenWhen: (previous, current) =>
                  current.status == AppBackupRestoreStatus.restoring &&
                  previous.status != AppBackupRestoreStatus.restoring,
              listener: (context, _) => _showProgress(context),
            ),
            BlocListener<AppBackupRestoreBloc, AppBackupRestoreState>(
              listenWhen: (previous, current) =>
                  previous.status == AppBackupRestoreStatus.restoring &&
                  current.status != AppBackupRestoreStatus.restoring &&
                  current.status != AppBackupRestoreStatus.restored,
              listener: (context, _) => _hideProgress(context),
            ),
            BlocListener<AppBackupRestoreBloc, AppBackupRestoreState>(
              listenWhen: (_, current) =>
                  current.status == AppBackupRestoreStatus.appMismatch && current.appMismatch != null,
              listener: (context, state) => _confirmAppMismatch(context, state.appMismatch!),
            ),
            BlocListener<AppBackupRestoreBloc, AppBackupRestoreState>(
              listenWhen: (_, current) => current.status == AppBackupRestoreStatus.failed,
              listener: (context, state) =>
                  BackupRestorePage._showError(context, state.error ?? ""),
            ),
          ],
          child: BlocBuilder<AppBackupRestoreBloc, AppBackupRestoreState>(
            builder: (context, state) => AppBackupScaffold(
              title: S.of(context).app_backup_restore_input_password,
              body: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    spacing: 24,
                    children: [
                      const CakeImageWidget(
                        imageUrl: "assets/new-ui/app_backup/restore_password.svg",
                        width: 78,
                        height: 92,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: AppBackupMessage(
                          title: S.of(context).app_backup_restore_password_title,
                          description: S.of(context).app_backup_restore_password_description,
                        ),
                      ),
                      Column(
                        spacing: 12,
                        children: [
                          BackupPasswordField(
                            controller: _controller,
                            onChanged: (input) => context
                                .read<AppBackupRestoreBloc>()
                                .add(RestorePasswordChanged(input)),
                            isError: state.showWrongPassword,
                            minLines: 3,
                          ),
                          NewPrimaryButton(
                            onPressed: () => _paste(context),
                            text: S.of(context).paste,
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            textColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      if (state.showWrongPassword)
                        Text(
                          S.of(context).app_backup_restore_wrong_password,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                letterSpacing: -0.07,
                              ),
                        ),
                    ],
                  ),
                ),
              ),
              footer: NewPrimaryButton(
                onPressed: () => context.read<AppBackupRestoreBloc>().add(RestoreSubmitted()),
                text: S.of(context).continue_text,
                color: Theme.of(context).colorScheme.primary,
                textColor: Theme.of(context).colorScheme.onPrimary,
                disabled: !state.canSubmit,
              ),
            ),
          ),
        ),
      );
}
