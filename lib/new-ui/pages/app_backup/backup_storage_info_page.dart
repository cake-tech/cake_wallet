import "package:cake_wallet/core/backup/app_backup_storage.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_storage_ui.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupStorageInfoPage extends StatelessWidget {
  const BackupStorageInfoPage({required this.storage, super.key});

  final AppBackupStorage storage;

  List<String> _descriptions(BuildContext context) => switch (storage) {
        AppBackupStorage.cloud => [S.of(context).app_backup_icloud_explainer],
        _ => [
            S.of(context).app_backup_custom_explainer,
            S.of(context).app_backup_custom_explainer_folder,
          ],
      };

  @override
  Widget build(BuildContext context) => AppBackupScaffold(
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
            child: Column(
              spacing: 24,
              children: [
                Column(
                  spacing: 12,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      spacing: 12,
                      children: [
                        CakeImageWidget(imageUrl: storage.iconPath, width: 24, height: 24),
                        Text(
                          storage.title(context),
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(letterSpacing: -0.08),
                        ),
                      ],
                    ),
                    for (final description in _descriptions(context))
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                              letterSpacing: -0.07,
                            ),
                      ),
                  ],
                ),
                const _FilesAppPreview(),
                AppBackupHint(
                  text: storage == AppBackupStorage.cloud
                      ? S.of(context).app_backup_icloud_hint
                      : S.of(context).app_backup_custom_hint,
                ),
              ],
            ),
          ),
        ),
        footer: BlocBuilder<AppBackupBloc, AppBackupState>(
          builder: (context, state) => NewPrimaryButton(
            onPressed: () => context.read<AppBackupBloc>().add(SaveRequested(storage)),
            text: S.of(context).continue_text,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            isLoading: state.status == AppBackupStatus.saving,
          ),
        ),
      );
}

class _FilesAppPreview extends StatelessWidget {
  const _FilesAppPreview();

  static const _sheetColor = Color(0xFFF7F7F7);
  static const _buttonColor = Color(0xFFFFFFFF);
  static const _searchColor = Color(0xFFE6E6E8);
  static const _accentColor = Color(0xFF0A84FF);

  Widget _circleButton(Widget child) => Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(color: _buttonColor, shape: BoxShape.circle),
        alignment: Alignment.center,
        child: child,
      );

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 300,
        height: 148,
        child: Stack(
          children: [
            Container(
              width: 300,
              height: 148,
              padding: const EdgeInsets.fromLTRB(12, 14, 12, 0),
              decoration: const BoxDecoration(
                color: _sheetColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(35.484)),
              ),
              child: Column(
                spacing: 10,
                children: [
                  Row(
                    spacing: 8,
                    children: [
                      _circleButton(
                        const Icon(CupertinoIcons.chevron_left, size: 18, color: Colors.black),
                      ),
                      const Text(
                        "Cake Wallet",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const Icon(
                        CupertinoIcons.chevron_down_circle,
                        size: 14,
                        color: Colors.black45,
                      ),
                      const Spacer(),
                      _circleButton(
                        const Icon(CupertinoIcons.ellipsis, size: 18, color: Colors.black),
                      ),
                      Container(
                        height: 32,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: _accentColor,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: const Text(
                          "Save",
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Container(
                    height: 30,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: _searchColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      spacing: 6,
                      children: [
                        Icon(CupertinoIcons.search, size: 14, color: Colors.black54),
                        Text("Search", style: TextStyle(fontSize: 13, color: Colors.black45)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Positioned(
              left: 253.59,
              top: 55.91,
              child: CakeImageWidget(
                imageUrl: "assets/new-ui/app_backup/arrow.svg",
                width: 18.6242,
                height: 79.0323,
              ),
            ),
          ],
        ),
      );
}
