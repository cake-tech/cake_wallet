import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SwapLimitPopup extends StatelessWidget {
  const SwapLimitPopup({super.key, required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  static const outlineColor = Color(0xFFFFB84E);
  static const backgroundColor = Color(0xFF8E5800);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Container(
        width: double.infinity,
        child: Observer(builder: (_) {
          final double? amount = double.tryParse(exchangeViewModel.depositAmount);
          final max = exchangeViewModel.limits.max ?? double.infinity;
          final min = exchangeViewModel.limits.min ?? 0;
          final tooLarge = amount != null && amount > max;
          final tooSmall = amount != null && amount < min;
          final show = amount != null && (tooLarge || tooSmall);

          final askText =
              tooLarge ? S.of(context).enter_less_than : S.of(context).enter_greater_than;
          final neededAmount = (tooLarge ? max : min).toString().withMaxDecimals(8);
          final currency = exchangeViewModel.depositCurrency.title;

          return Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              opacity: show ? 1 : 0,
              child: Container(
                height: show ? null : 0,
                decoration: BoxDecoration(
                    color: backgroundColor, borderRadius: BorderRadius.circular(99999)),
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    "$askText $neededAmount $currency",
                    textAlign: TextAlign.center,
                    style:
                        TextStyle(color: outlineColor, fontWeight: FontWeight.w500, fontSize: 12),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
