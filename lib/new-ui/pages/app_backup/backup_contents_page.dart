import "package:cake_wallet/core/backup/app_backup_contents.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_Item_checkbox.dart";
import "package:cake_wallet/entities/new_ui_entities/list_item/list_item_regular_row.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_page.dart";
import "package:cake_wallet/new-ui/pages/app_backup/app_backup_scaffold.dart";
import "package:cake_wallet/new-ui/pages/app_backup/backup_password_page.dart";
import "package:cake_wallet/new-ui/viewmodels/app_backup/app_backup_bloc.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/new_list_row/new_list_section.dart";
import "package:cw_core/currency_for_wallet_type.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class BackupContentsPage extends StatelessWidget {
  const BackupContentsPage({this.forSetup = true, super.key});

  final bool forSetup;

  void _continue(BuildContext context) => forSetup
      ? AppBackupPage.push(context, const BackupPasswordPage())
      : Navigator.of(context).pop();

  @override
  Widget build(BuildContext context) => BlocBuilder<AppBackupBloc, AppBackupState>(
        builder: (context, state) => PopScope(
          canPop: state.config.canContinue || state.config.wallets.isEmpty,
          child: AppBackupScaffold(
            body: state is AppBackupLoading
                ? const Center(child: CupertinoActivityIndicator())
                : _BackupContentsList(state: state),
            footer: state is AppBackupLoading
                ? null
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    spacing: 12,
                    children: [
                      if (!state.config.canContinue)
                        Text(
                          S.of(context).app_backup_select_wallet_error,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context).colorScheme.error,
                                letterSpacing: -0.06,
                              ),
                        ),
                      NewPrimaryButton(
                        onPressed: () => _continue(context),
                        text: S.of(context).continue_text,
                        color: Theme.of(context).colorScheme.primary,
                        textColor: Theme.of(context).colorScheme.onPrimary,
                        disabled: !state.config.canContinue,
                      ),
                    ],
                  ),
          ),
        ),
      );
}

class _BackupContentsList extends StatelessWidget {
  const _BackupContentsList({required this.state});

  final AppBackupState state;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.symmetric(vertical: 24),
        children: [
          Center(
            child: SizedBox(
              width: 250,
              child: Text(
                S.of(context).app_backup_contents_title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(letterSpacing: -0.07),
              ),
            ),
          ),
          const SizedBox(height: 24),
          NewListSections(
            sections: {
              "": [
                ListItemRegularRow(
                  keyValue: "app_backup_file",
                  label: S.of(context).app_backup_file,
                  iconPath: "assets/new-ui/app_backup/backup_file_small.svg",
                  showArrow: false,
                  trailingWidget: Text(
                    state.config.totalSize == null ? "..." : formatBackupSize(state.config.totalSize!),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          letterSpacing: -0.07,
                        ),
                  ),
                ),
              ],
            },
          ),
          const SizedBox(height: 24),
          Text(
            S.of(context).app_backup_choose_wallets,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  letterSpacing: -0.06,
                ),
          ),
          const SizedBox(height: 24),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              spacing: 16,
              children: [
                Expanded(
                  child: Text(
                    S.of(context).wallets,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(letterSpacing: -0.06),
                  ),
                ),
                _SelectionLink(
                  text: S.of(context).unselect_all,
                  onTap: () => context.read<AppBackupBloc>().add(AllWalletsDeselected()),
                ),
                _SelectionLink(
                  text: S.of(context).select_all,
                  onTap: () => context.read<AppBackupBloc>().add(AllWalletsSelected()),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          NewListSections(
            sections: {
              "": [
                for (final info in state.config.wallets)
                  ListItemCheckbox(
                    keyValue: info.id,
                    label: info.name,
                    subtitle: state.config.walletSizes[info.id] == null
                        ? "…"
                        : formatBackupSize(state.config.walletSizes[info.id]!),
                    iconPath: walletTypeToCryptoCurrency(info.type).iconPath,
                    value: state.config.isSelected(info),
                    onChanged: (_) => context.read<AppBackupBloc>().add(WalletToggled(info.id)),
                  ),
              ],
            },
          ),
        ],
      );
}

class _SelectionLink extends StatelessWidget {
  const _SelectionLink({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Text(
          text,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
                letterSpacing: -0.06,
              ),
        ),
      );
}
