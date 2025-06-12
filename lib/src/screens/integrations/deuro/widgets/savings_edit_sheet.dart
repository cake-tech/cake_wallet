import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/numpad.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class SavingEditPage extends BasePage {
  final bool isAdding;

  SavingEditPage({required this.isAdding});

  String get title =>
      isAdding ? S.current.deuro_savings_add : S.current.deuro_savings_remove;

  @override
  Widget body(BuildContext context) => _SavingsEditBody();
}

class _SavingsEditBody extends StatefulWidget {
  const _SavingsEditBody();

  @override
  State<StatefulWidget> createState() => _SavingsEditBodyState();
}

class _SavingsEditBodyState extends State<_SavingsEditBody> {
  @override
  void initState() {
    WidgetsBinding.instance
        .addPostFrameCallback((_) => _numpadFocusNode.requestFocus());
    super.initState();
  }

  @override
  void dispose() {
    _numpadFocusNode.dispose();
    super.dispose();
  }

  String amount = '0';
  final FocusNode _numpadFocusNode = FocusNode();

  @override
  Widget build(BuildContext context) => SafeArea(
        child: Column(children: [
          Expanded(
              child: Center(
            child: Padding(
              padding: const EdgeInsets.only(left: 26, right: 26, top: 10),
              child: AutoSizeText(
                "${amount.toString()} dEuro",
                maxLines: 1,
                maxFontSize: 60,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 60,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          )),
          NumberPad(
            focusNode: _numpadFocusNode,
            onNumberPressed: (i) => setState(
              () => amount = amount == '0' ? i.toString() : '${amount}${i}',
            ),
            onDeletePressed: () => setState(
              () => amount = amount.length > 1
                  ? amount.substring(0, amount.length - 1)
                  : '0',
            ),
            onDecimalPressed: () =>
                setState(() => amount = '${amount.replaceAll('.', '')}.'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 34),
            child: LoadingPrimaryButton(
              onPressed: () => Navigator.pop(context, amount),
              text: S.of(context).confirm,
              color: Theme.of(context).colorScheme.primary,
              textColor: Theme.of(context).colorScheme.onPrimary,
              isLoading: false,
              isDisabled: false,
            ),
          )
        ]),
      );
}
