import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/integrations/deuro/widgets/numpad.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:flutter/material.dart';

class SavingsEditSheet extends BaseBottomSheet {
  final String? balance;
  final String? balanceTitle;

  const SavingsEditSheet({
    required super.titleText,
    super.titleIconPath,
    this.balance,
    this.balanceTitle,
    required super.footerType, required super.maxHeight,
  });

  @override
  Widget contentWidget(BuildContext context) => SizedBox(
        height: 500,
        child: _SavingsEditBody(
          balance: balance,
          balanceTitle: balanceTitle,
        ),
      );

  Widget footerWidget(BuildContext context) => SizedBox.shrink();
}

class _SavingsEditBody extends StatefulWidget {
  final String? balance;
  final String? balanceTitle;

  const _SavingsEditBody({this.balance, this.balanceTitle});

  @override
  State<StatefulWidget> createState() => _SavingsEditBodyState();
}

class _SavingsEditBodyState extends State<_SavingsEditBody> {
  @override
  void initState() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _numpadFocusNode.requestFocus());
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
                maxFontSize: 32,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      fontSize: 32,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
          )),
          if (widget.balance != null && widget.balanceTitle != null) ...[
            Divider(),
            AssetBalanceRow(
              title: widget.balanceTitle!,
              amount: widget.balance!,
              onAllPressed: () => setState(() => amount = widget.balance!),
            ),
          ],
          NumberPad(
            focusNode: _numpadFocusNode,
            onNumberPressed: (i) => setState(
              () => amount = amount == '0' ? i.toString() : '${amount}${i}',
            ),
            onDeletePressed: () => setState(
              () => amount = amount.length > 1 ? amount.substring(0, amount.length - 1) : '0',
            ),
            onDecimalPressed: () => setState(() => amount = '${amount.replaceAll('.', '')}.'),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
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

class AssetBalanceRow extends StatelessWidget {
  final String title;
  final String amount;
  final VoidCallback onAllPressed;

  const AssetBalanceRow({
    super.key,
    required this.title,
    required this.amount,
    required this.onAllPressed,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                            height: 1,
                          ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                AutoSizeText(
                  amount,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w400,
                        height: 1,
                      ),
                  maxLines: 1,
                  textAlign: TextAlign.start,
                ),
              ],
            ),
            SizedBox(
              child: Center(
                child: InkWell(
                  onTap: onAllPressed,
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                    ),
                    padding: EdgeInsets.fromLTRB(15, 10, 15, 10),
                    child: Text(
                      S.of(context).all,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}
