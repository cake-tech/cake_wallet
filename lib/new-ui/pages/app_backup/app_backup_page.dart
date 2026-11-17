import "package:bloc_presentation/bloc_presentation.dart";
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
  Route<void>? _creatingRoute;

  void _replaceStack(Widget page) => _navigatorKey.currentState
      ?.pushAndRemoveUntil(CupertinoPageRoute(builder: (_) => page), (_) => false);

  void _showCreating() {
    final route = CupertinoPageRoute<void>(builder: (_) => const BackupCreatingPage());
    _creatingRoute = route;
    _navigatorKey.currentState?.push(route);
  }

  void _hideCreating() {
    final route = _creatingRoute;
    _creatingRoute = null;
    if (route == null || !route.isActive) return;
    route.isCurrent
        ? _navigatorKey.currentState?.pop()
        : _navigatorKey.currentState?.removeRoute(route);
  }

  void _onPresentation(AppBackupPresentation event) {
    switch (event) {
      case BackupCreated():
        _replaceStack(const BackupStoragePage());
      case BackupSaved(:final isFirstBackup):
        if (isFirstBackup) _replaceStack(const BackupCompletePage());
      case BackupFailed(:final error):
        _hideCreating();
        _showError(error);
      case PasswordRegenerated():
        _navigatorKey.currentState
            ?.push(CupertinoPageRoute(builder: (_) => const BackupPasswordPage()));
      case PasswordSaved():
        _navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
  }

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
                  previous is! AppBackupCreating &&
                  current is AppBackupCreating &&
                  !current.config.isSetupCompleted,
              listener: (_, __) => _showCreating(),
            ),
            BlocPresentationListener<AppBackupBloc, AppBackupPresentation>(
              listener: (_, event) => _onPresentation(event),
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
