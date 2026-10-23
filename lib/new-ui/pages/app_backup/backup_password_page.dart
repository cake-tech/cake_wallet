import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_verify_page.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/themes/core/theme_extension.dart";
import "package:cake_wallet/utils/clipboard_util.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupPasswordPage extends StatelessWidget {
  const BackupPasswordPage({this.forSetup = true, super.key});

  final bool forSetup;

  String _password(AppBackupState state) => forSetup ? state.passwordToVerify : state.password;

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBackupBloc, AppBackupState>(
        buildWhen: (previous, current) => _password(previous) != _password(current),
        builder: (context, state) => _BackupPasswordContent(
          password: _password(state),
          onSaved: forSetup
              ? () => AppBackupPage.push(context, const BackupVerifyPage())
              : Navigator.of(context).pop,
        ),
      );
}

class _BackupPasswordContent extends StatelessWidget {
  const _BackupPasswordContent({required this.password, required this.onSaved});

  final String password;
  final VoidCallback onSaved;

  @override
  Widget build(BuildContext context) => AppBackupScaffold(
        body: password.isEmpty
            ? const Center(child: CupertinoActivityIndicator())
            : Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    spacing: 24,
                    children: [
                      const CakeImageWidget(
                        imageUrl: "assets/new-ui/app_backup/backup_password.svg",
                        width: 78,
                        height: 92,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: AppBackupMessage(
                          title: S.of(context).app_backup_password_title,
                          description: S.of(context).app_backup_password_description,
                          titleStyle: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.copyWith(letterSpacing: -0.07),
                        ),
                      ),
                      Column(
                        spacing: 12,
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.surfaceContainer,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: BackupPasswordText(password: password),
                          ),
                          NewPrimaryButton(
                            onPressed: () => ClipboardUtil.copyToClipboard(
                              context,
                              password,
                              isSensitive: true,
                            ),
                            text: S.of(context).copy,
                            image: const CakeImageWidget(
                              imageUrl: "assets/new-ui/app_backup/copy.svg",
                              width: 24,
                              height: 24,
                            ),
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            textColor: Theme.of(context).colorScheme.primary,
                          ),
                        ],
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(15),
                        decoration: BoxDecoration(
                          color: context.customColors.warningContainerColor,
                          border:
                              Border.all(color: context.customColors.warningOutlineColor, width: 2),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Text(
                          S.of(context).app_backup_password_warning,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: context.customColors.warningOutlineColor,
                                letterSpacing: -0.06,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        footer: NewPrimaryButton(
          onPressed: onSaved,
          text: S.of(context).app_backup_password_saved,
          color: Theme.of(context).colorScheme.primary,
          textColor: Theme.of(context).colorScheme.onPrimary,
          disabled: password.isEmpty,
        ),
      );
}

class BackupPasswordText extends StatelessWidget {
  const BackupPasswordText({required this.password, this.color, super.key});

  final String password;
  final Color? color;

  static const _digitColor = Color(0xFF91B0FF);
  static const _separatorColor = Color(0xFFF7BC1A);

  @override
  Widget build(BuildContext context) => Text.rich(
        TextSpan(
          children: [
            for (final match in RegExp(r"\d+|-|[^\d-]+").allMatches(password))
              TextSpan(
                text: match.group(0),
                style: color != null
                    ? null
                    : match.group(0) == "-"
                        ? const TextStyle(color: _separatorColor)
                        : RegExp(r"^\d+$").hasMatch(match.group(0)!)
                            ? const TextStyle(color: _digitColor)
                            : null,
              ),
          ],
        ),
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: "IBM Plex Mono",
          fontSize: 16,
          letterSpacing: -0.08,
          color: color ?? Theme.of(context).colorScheme.onSurface,
        ),
      );
}
