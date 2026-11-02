import "package:cake_wallet/core/execution_state.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/alert_with_one_action.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:cake_wallet/view_model/wallet_account_list/account_edit_or_create_view_model.dart";
import "package:cw_core/generate_name.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

class AccountCreationModal extends StatefulWidget {
  const AccountCreationModal({required this.viewModel, super.key});

  final WalletAccountEditOrCreateViewModel viewModel;

  @override
  State<AccountCreationModal> createState() => _AccountCreationModalState();
}

class _AccountCreationModalState extends State<AccountCreationModal> {
  static const int maxAccountNameLength = 25;

  final TextEditingController _controller = TextEditingController();
  bool _loading = false;

  bool get _canContinue =>
      _controller.text.trim().isNotEmpty && _controller.text.length <= maxAccountNameLength;

  Future<void> _generateAccountName() async {
    final generatedName = await generateName();
    if (!mounted) {
      return;
    }
    setState(() => _controller.text = generatedName.length > maxAccountNameLength
        ? generatedName.substring(0, maxAccountNameLength)
        : generatedName);
  }

  Future<void> _save() async {
    if (_loading || !_canContinue) {
      return;
    }

    setState(() => _loading = true);
    widget.viewModel.label = _controller.text;

    late final String errorMessage;
    try {
      await widget.viewModel.save();
      if (!mounted) {
        return;
      }

      final state = widget.viewModel.state;
      if (state is ExecutedSuccessfullyState) {
        Navigator.of(context).pop(true);
        return;
      }
      errorMessage = state is FailureState ? state.error : S.of(context).error_while_processing;
    } catch (error) {
      errorMessage = error.toString();
    }

    if (!mounted) {
      return;
    }
    setState(() => _loading = false);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertWithOneAction(
        alertTitle: S.of(dialogContext).error,
        alertContent: errorMessage,
        buttonText: S.of(dialogContext).ok,
        buttonAction: Navigator.of(dialogContext).pop,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
        canPop: !_loading,
        child: _buildContent(context),
      );

  Widget _buildContent(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
              children: [
                ModalTopBar(
                  title: S.of(context).create_account,
                  trailingIcon: const Icon(Icons.close),
                  trailingSemanticLabel: S.of(context).close,
                  onTrailingPressed: Navigator.of(context).maybePop,
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 32, 18, 24),
                    child: Column(
                      spacing: 24,
                      children: [
                        const CakeImageWidget(
                          imageUrl: "assets/new-ui/account_education/create_account.svg",
                          width: 125,
                          height: 125,
                        ),
                        Text(
                          S.of(context).account_creation_description,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            fontSize: 14,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  maxLength: maxAccountNameLength,
                                  inputFormatters: [
                                    LengthLimitingTextInputFormatter(maxAccountNameLength)
                                  ],
                                  textInputAction: TextInputAction.done,
                                  onChanged: (_) => setState(() {}),
                                  decoration: InputDecoration(
                                    hintText: S.of(context).account_name,
                                    counterText: "",
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: Semantics(
                                  button: true,
                                  label: S.of(context).generate_name,
                                  onTap: _generateAccountName,
                                  child: ExcludeSemantics(
                                    child: GestureDetector(
                                      onTap: _generateAccountName,
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.surfaceContainerHigh,
                                          borderRadius: BorderRadius.circular(5),
                                        ),
                                        child: CakeImageWidget(
                                          imageUrl: "assets/new-ui/randomize.svg",
                                          colorFilter: ColorFilter.mode(
                                            Theme.of(context).colorScheme.primary,
                                            BlendMode.srcIn,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                  child: SizedBox(
                    width: double.infinity,
                    child: NewPrimaryButton(
                      onPressed: _save,
                      text: S.of(context).continue_text,
                      color: Theme.of(context).colorScheme.primary,
                      textColor: Theme.of(context).colorScheme.onPrimary,
                      isLoading: _loading,
                      disabled: !_canContinue,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
}
