import 'package:flutter/material.dart';

class AnonpayTransactionRow extends StatelessWidget {
  AnonpayTransactionRow({
    required this.provider,
    required this.createdAt,
    required this.currency,
    required this.onTap,
    required this.amount,
    super.key,
  });

  final VoidCallback? onTap;
  final String provider;
  final String createdAt;
  final String amount;
  final String currency;

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
                      provider,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      amount + ' ' + currency,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                  ]),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        createdAt,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _getImage() => ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: Image.asset('assets/images/trocador.png', width: 36, height: 36));
}
