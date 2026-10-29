import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";

class BackupCreatingPage extends StatefulWidget {
  const BackupCreatingPage({this.title, super.key});

  final String? title;

  @override
  State<BackupCreatingPage> createState() => _BackupCreatingPageState();
}

class _BackupCreatingPageState extends State<BackupCreatingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spinner =
      AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat();

  @override
  void dispose() {
    _spinner.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: false,
        child: AppBackupScaffold(
          showBackButton: false,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 24,
                children: [
                  const CupertinoActivityIndicator(radius: 50,),
                  AppBackupMessage(
                    title: widget.title ?? S.of(context).app_backup_creating,
                    description: S.of(context).app_backup_creating_description,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
}
