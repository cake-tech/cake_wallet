import 'package:cake_wallet/buy/buy_provider_description.dart';
import 'package:cake_wallet/buy/get_buy_provider_icon.dart';
import 'package:flutter/material.dart';

class OrderRow extends StatelessWidget {
  OrderRow({
    required this.provider,
    required this.from,
    required this.to,
    required this.createdAtFormattedDate,
    this.onTap,
    this.formattedAmount,
    super.key,
  });

  final VoidCallback? onTap;
  final BuyProviderDescription provider;
  final String from;
  final String to;
  final String createdAtFormattedDate;
  final String? formattedAmount;

  @override
  Widget build(BuildContext context) {
    final iconColor = Theme.of(context).colorScheme.onSurfaceVariant;

    final providerIcon = getBuyProviderIcon(provider, iconColor: iconColor);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (providerIcon != null)
              Padding(
                padding: EdgeInsets.only(right: 12),
                child: providerIcon,
              ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: <Widget>[
                    Text(
                      '$from → $to',
                      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    formattedAmount != null
                        ? Text(
                            formattedAmount! + ' ' + to,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                          )
                        : Container()
                  ]),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        createdAtFormattedDate,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
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
}
