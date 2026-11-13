import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/wallet_icon_editor.dart";
import "package:cake_wallet/src/screens/base_page.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:cake_wallet/src/widgets/primary_button.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_group_edit/wallet_group_edit_bloc.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_group_edit/wallet_group_edit_event.dart";
import "package:cake_wallet/view_model/wallet_list/wallet_group_edit/wallet_group_edit_state.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class WalletEditPage extends BasePage {
  WalletEditPage()
      : _formKey = GlobalKey<FormState>(),
        _labelController = TextEditingController();

  final GlobalKey<FormState> _formKey;
  final TextEditingController _labelController;

  @override
  String get title => S.current.wallet_list_edit_wallet;

  @override
  Widget body(BuildContext context) => MultiBlocListener(
        listeners: [
          BlocListener<WalletEditBloc, WalletEditState>(
            listenWhen: (prev, curr) =>
                prev.group?.groupName == null && curr.group?.groupName != null,
            listener: (context, state) => _labelController.text = state.group!.groupName!,
          ),
          BlocListener<WalletEditBloc, WalletEditState>(
            listenWhen: (prev, curr) => prev.error != curr.error,
            listener: (context, state) => _formKey.currentState?.validate(),
          ),
          BlocListener<WalletEditBloc, WalletEditState>(
            listenWhen: (prev, curr) => !prev.closeRequested && curr.closeRequested,
            listener: (context, state) => Navigator.of(context).pop(),
          ),
        ],
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: <Widget>[
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          BlocBuilder<WalletEditBloc, WalletEditState>(
                            buildWhen: (p, c) => p.group?.icon != c.group?.icon,
                            builder: (context, state) => WalletIconEditor(
                              icon: state.group?.icon,
                              cryptoTypes:
                                  state.group?.wallets.map((w) => w.type).toSet().toList() ??
                                      const [],
                              onChanged: (icon) => context
                                  .read<WalletEditBloc>()
                                  .add(WalletEditIconChanged(icon)),
                            ),
                          ),
                          BlocBuilder<WalletEditBloc, WalletEditState>(
                            buildWhen: (p, c) => p.error != c.error,
                            builder: (context, state) {
                              if (state.error != WalletEditError.iconFailed) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  S.of(context).unknown_error,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Theme.of(context).colorScheme.error,
                                      ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 32),
                          BaseTextFormField(
                            key: const ValueKey("wallet_edit_page_name_input_key"),
                            controller: _labelController,
                            hintText: S.of(context).wallet_list_wallet_name,
                            validator: (value) {
                              final localError = WalletNameValidator()(value);
                              if (localError != null) return localError;

                              return switch (context.read<WalletEditBloc>().state.error) {
                                WalletEditError.nameTaken => S.of(context).wallet_name_exists,
                                WalletEditError.renameFailed => S.of(context).unknown_error,
                                _ => null,
                              };
                            },
                            onChanged: (value) =>
                                context.read<WalletEditBloc>().add(WalletEditNameChanged(value)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                BlocBuilder<WalletEditBloc, WalletEditState>(
                  buildWhen: (prev, curr) => prev.canSubmitRename != curr.canSubmitRename,
                  builder: (context, state) => LoadingPrimaryButton(
                    key: const ValueKey("wallet_edit_page_save_button_key"),
                    isDisabled: !state.canSubmitRename,
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        context.read<WalletEditBloc>().add(WalletEditRenameSubmitted());
                      }
                    },
                    text: S.of(context).save,
                    color: Theme.of(context).colorScheme.primary,
                    textColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
