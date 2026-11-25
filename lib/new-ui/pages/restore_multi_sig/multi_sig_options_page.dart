import "package:cake_wallet/core/wallet_name_validator.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/restore_multi_sig/restore_multi_sig_bloc.dart";
import "package:cake_wallet/new-ui/widgets/modern_button.dart";
import "package:cake_wallet/new-ui/widgets/new_primary_button.dart";
import "package:cake_wallet/src/widgets/base_text_form_field.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class MultiSigOptionsPage extends StatefulWidget {
  const MultiSigOptionsPage({super.key});

  @override
  State<MultiSigOptionsPage> createState() => _MultiSigOptionsPageState();
}

class _MultiSigOptionsPageState extends State<MultiSigOptionsPage> {
  static const _maxSigners = 15;

  int _requiredSigners = 2;
  int _totalSigners = 3;
  final _formKey = GlobalKey<FormState>();
  final _walletNameController = TextEditingController();

  @override
  void dispose() {
    _walletNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) => SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight - 48),
                  child: IntrinsicHeight(
                    child: Column(
                      spacing: 48,
                      children: [
                        Form(
                          key: _formKey,
                          child: BaseTextFormField(
                            key: const ValueKey("restore_multi_sig_page_wallet_name_field_key"),
                            controller: _walletNameController,
                            hintText: S.of(context).wallet_name,
                            validator: WalletNameValidator(),
                          ),
                        ),
                        Expanded(
                          child: Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              spacing: 24,
                              children: [
                                _SignerCounter(
                                  keyPrefix: "restore_multi_sig_page_required",
                                  value: _requiredSigners,
                                  onIncrement: _requiredSigners < _totalSigners
                                      ? () => setState(() => _requiredSigners++)
                                      : null,
                                  onDecrement: _requiredSigners > 1
                                      ? () => setState(() => _requiredSigners--)
                                      : null,
                                ),
                                Text("/", style: _numberStyle(context)),
                                _SignerCounter(
                                  keyPrefix: "restore_multi_sig_page_total",
                                  value: _totalSigners,
                                  onIncrement: _totalSigners < _maxSigners
                                      ? () => setState(() => _totalSigners++)
                                      : null,
                                  onDecrement: _totalSigners > _requiredSigners
                                      ? () => setState(() => _totalSigners--)
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            child: NewPrimaryButton(
              key: const ValueKey("restore_multi_sig_page_next_button_key"),
              onPressed: _onNext,
              text: S.of(context).seed_language_next,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
        ],
      );

  void _onNext() {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }

    context
        .read<RestoreMultiSigBloc>()
        .add(SetOptions(_walletNameController.text, _requiredSigners, _totalSigners));
  }
}

TextStyle? _numberStyle(BuildContext context) =>
    Theme.of(context).textTheme.displayLarge?.copyWith(fontWeight: FontWeight.w600);

class _SignerCounter extends StatelessWidget {
  const _SignerCounter({
    required this.keyPrefix,
    required this.value,
    required this.onIncrement,
    required this.onDecrement,
  });

  final String keyPrefix;
  final int value;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        spacing: 16,
        children: [
          _button(
            context,
            ValueKey("${keyPrefix}_increment_button_key"),
            Icons.add,
            S.of(context).add,
            onIncrement,
          ),
          Text("$value", style: _numberStyle(context)),
          _button(
            context,
            ValueKey("${keyPrefix}_decrement_button_key"),
            Icons.remove,
            S.of(context).remove,
            onDecrement,
          ),
        ],
      );

  Widget _button(
    BuildContext context,
    Key key,
    IconData icon,
    String semanticLabel,
    VoidCallback? onPressed,
  ) =>
      Opacity(
        opacity: onPressed != null ? 1 : 0.4,
        child: ModernButton(
          key: key,
          size: 48,
          icon: Icon(icon),
          semanticLabel: semanticLabel,
          onPressed: onPressed ?? () {},
        ),
      );
}
