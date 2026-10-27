import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupVerifyPage extends StatefulWidget {
  const BackupVerifyPage({super.key});

  @override
  State<BackupVerifyPage> createState() => _BackupVerifyPageState();
}

class _BackupVerifyPageState extends State<BackupVerifyPage> {
  late final TextEditingController _controller =
      TextEditingController(text: _verification(context.read<AppBackupBloc>().state).input);

  static AppBackupVerifying _verification(AppBackupState state) =>
      state is AppBackupVerifying ? state : AppBackupVerifying(state.config);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      BlocSelector<AppBackupBloc, AppBackupState, AppBackupVerifying>(
        selector: _verification,
        builder: (context, verification) => AppBackupScaffold(
          body: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Column(
                spacing: 24,
                children: [
                  const CakeImageWidget(
                    imageUrl: "assets/new-ui/app_backup/verify.svg",
                    width: 75,
                    height: 75,
                  ),
                  AppBackupMessage(
                    title: S.of(context).app_backup_verify_title,
                    description: S.of(context).app_backup_verify_description,
                  ),
                  BackupPasswordField(
                    controller: _controller,
                    onChanged: (input) =>
                        context.read<AppBackupBloc>().add(VerificationChanged(input)),
                    isError: verification.showMismatch,
                    isValid: verification.passwordMatches,
                  ),
                  if (verification.passwordMatches)
                    Text(
                      S.of(context).app_backup_password_matches,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.green,
                            letterSpacing: -0.07,
                          ),
                    ),
                  if (verification.showMismatch) ...[
                    Text(
                      S.of(context).app_backup_password_mismatch,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            letterSpacing: -0.07,
                          ),
                    ),
                    GestureDetector(
                      onTap: Navigator.of(context).pop,
                      child: Text(
                        S.of(context).app_backup_go_back_hint,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              letterSpacing: -0.07,
                            ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          footer: NewPrimaryButton(
            onPressed: () => context.read<AppBackupBloc>().add(VerificationSubmitted()),
            text: S.of(context).continue_text,
            color: Theme.of(context).colorScheme.primary,
            textColor: Theme.of(context).colorScheme.onPrimary,
            disabled: !verification.canSubmit,
          ),
        ),
      );
}
