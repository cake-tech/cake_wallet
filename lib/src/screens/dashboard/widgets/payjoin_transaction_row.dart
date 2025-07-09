import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class PayjoinTransactionRow extends StatelessWidget {
  PayjoinTransactionRow({
    required this.createdAt,
    required this.currency,
    required this.onTap,
    required this.amount,
    required this.state,
    required this.isSending,
    super.key,
  });

  final VoidCallback? onTap;
  final String createdAt;
  final String amount;
  final String currency;
  final String state;
  final bool isSending;

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _getImage(),
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Text(
                      "${isSending ? S.current.outgoing : S.current.incoming} Payjoin",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    Text(
                      amount + ' ' + currency,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    )
                  ]),
                  SizedBox(height: 5),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Text(
                      createdAt,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    Text(
                      state,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ])
                ],
              ))
            ],
          ),
        ));
  }

  Widget _getImage() => ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: Image.asset(
          'assets/images/payjoin.png',
          width: 36,
          height: 36,
        ),
      );
}
