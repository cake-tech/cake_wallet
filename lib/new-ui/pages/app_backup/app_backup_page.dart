import "package:cake_wallet/core/backup/app_backup_preferences.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_complete_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_creating_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_intro_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_management_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_password_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_storage_page.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/router.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class AppBackupPage extends StatefulWidget {
  const AppBackupPage({required this.preferences, super.key});

  final AppBackupPreferences preferences;

  static _AppBackupPageState _of(BuildContext context) =>
      context.findAncestorStateOfType<_AppBackupPageState>()!;

  static Future<T?> push<T>(BuildContext context, Widget page) =>
      Navigator.of(context).push<T>(CupertinoPageRoute(builder: (_) => page));

  static void exit(BuildContext context) => Navigator.of(_of(context).context).maybePop();

  static void exitToHome(BuildContext context) =>
      Navigator.of(context, rootNavigator: true).popUntil((route) => route.isFirst);

  static void showManagement(BuildContext context) =>
      _of(context)._replaceStack(const BackupManagementPage());

  @override
  State<AppBackupPage> createState() => _AppBackupPageState();
}

class _AppBackupPageState extends State<AppBackupPage> {
  final _navigatorKey = GlobalKey<NavigatorState>();

  void _replaceStack(Widget page) => _navigatorKey.currentState
      ?.pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => page), (_) => false);

  Future<void> _showError(String error) => showDialog<void>(
        context: _navigatorKey.currentContext!,
        builder: (dialogContext) => AlertWithOneAction(
          alertTitle: S.of(dialogContext).app_backup_failed,
          alertContent: error,
          buttonText: S.of(dialogContext).ok,
          buttonAction: Navigator.of(dialogContext).pop,
        ),
      );

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => getIt.get<AppBackupBloc>(),
        child: MultiBlocListener(
          listeners: [
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (previous, current) =>
                  current.status == AppBackupStatus.creating &&
                  previous.status != AppBackupStatus.creating &&
                  !current.isSetupCompleted,
              listener: (_, __) => _navigatorKey.currentState
                  ?.push(CupertinoPageRoute(builder: (_) => const BackupCreatingPage())),
            ),
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (previous, current) =>
                  current.status == AppBackupStatus.readyToSave &&
                  previous.status == AppBackupStatus.creating,
              listener: (_, __) => _replaceStack(const BackupStoragePage()),
            ),
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (previous, current) =>
                  current.status == AppBackupStatus.saved && !previous.isSetupCompleted,
              listener: (_, __) => _replaceStack(const BackupCompletePage()),
            ),
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (previous, current) =>
                  current.status == AppBackupStatus.failed &&
                  previous.status == AppBackupStatus.creating &&
                  !current.isSetupCompleted,
              listener: (_, __) => _navigatorKey.currentState?.pop(),
            ),
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (_, current) => current.status == AppBackupStatus.failed,
              listener: (_, state) => _showError(state.error ?? ""),
            ),
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (previous, current) =>
                  current.pendingPassword != null &&
                  current.pendingPassword != previous.pendingPassword,
              listener: (_, __) => _navigatorKey.currentState
                  ?.push(CupertinoPageRoute(builder: (_) => const BackupPasswordPage())),
            ),
            BlocListener<AppBackupBloc, AppBackupState>(
              listenWhen: (previous, current) =>
                  previous.pendingPassword != null && current.pendingPassword == null,
              listener: (_, __) => _navigatorKey.currentState?.popUntil((route) => route.isFirst),
            ),
          ],
          child: NavigatorPopHandler(
            onPopWithResult: (_) => _navigatorKey.currentState?.maybePop(),
            child: Navigator(
              key: _navigatorKey,
              onGenerateInitialRoutes: (_, __) => [
                CupertinoPageRoute(
                  builder: (_) => widget.preferences.isSetupCompleted
                      ? const BackupManagementPage()
                      : const BackupIntroPage(),
                ),
              ],
              onGenerateRoute: createRoute,
            ),
          ),
        ),
      );
}
