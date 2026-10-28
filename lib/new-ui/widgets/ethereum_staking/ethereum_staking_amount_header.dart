import "package:cake_wallet/new-ui/viewmodels/fiat_rate/fiat_rate_cubit.dart";
import "package:cake_wallet/new-ui/widgets/money/currency_symbol_text.dart";
import "package:cake_wallet/new-ui/widgets/money/money_text.dart";
import "package:cw_core/amount/exchange_rate.dart";
import "package:cw_core/amount/money.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class EthereumStakingAmountHeader extends StatelessWidget {
  const EthereumStakingAmountHeader(
    this.amount, {
    super.key,
    this.approximate = false,
    this.isHiddenAmount,
  });

  final Money amount;
  final bool approximate;
  final bool? isHiddenAmount;

  @override
  Widget build(BuildContext context) => BlocBuilder<FiatRateCubit, ExchangeRate?>(
        builder: (context, fiatRate) {
          final theme = Theme.of(context);
          final fiat = fiatRate?.convert(amount);
          final headline = fiat ?? amount;
          final headlineStyle = theme.textTheme.displayMedium;
          final cryptoStyle = TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurfaceVariant,
          );

          return MergeSemantics(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              spacing: 4,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    spacing: 8,
                    children: [
                      MoneyText(
                        headline,
                        showSymbol: false,
                        fractionalDigits: fiat == null ? 8 : 2,
                        trimZeros: fiat == null,
                        isHiddenAmount: isHiddenAmount,
                        style: headlineStyle,
                      ),
                      CurrencySymbolText(
                        headline.currency,
                        style: headlineStyle?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (fiat != null)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (approximate) Text("≈ ", style: cryptoStyle),
                      MoneyText(amount, isHiddenAmount: isHiddenAmount, style: cryptoStyle),
                    ],
                  ),
              ],
            ),
          );
        },
      );
}
