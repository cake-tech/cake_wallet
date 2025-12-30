import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/exchange/exchange_provider_description.dart';
import 'package:cw_core/crypto_currency.dart';

class TradeRow extends StatelessWidget {
  TradeRow({
    required this.provider,
    required this.from,
    required this.to,
    required this.createdAtFormattedDate,
    this.onTap,
    this.formattedAmount,
    this.formattedReceiveAmount,
    required this.swapState,
    required this.chainName,
    super.key,
  });

  final VoidCallback? onTap;
  final ExchangeProviderDescription provider;
  final CryptoCurrency from;
  final CryptoCurrency to;
  final String? createdAtFormattedDate;
  final String? formattedAmount;
  final String? formattedReceiveAmount;
  final TradeState swapState;
  final String chainName;

  @override
  Widget build(BuildContext context) {
    final amountCrypto = from.toString();
    final receiveAmountCrypto = to.toString();

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
        color: Colors.transparent,
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(50),
                  child:
                      ImageUtil.getImageFromPath(imagePath: provider.image, height: 36, width: 36),
                ),
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _statusColor(context, swapState),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '${from.toString()}($chainName) → ${to.toString()}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.primary),
                      ),
                      formattedAmount != null
                          ? Text(
                              formattedAmount! + ' ' + amountCrypto,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurface,
                                  ),
                            )
                          : Container()
                    ],
                  ),
                  SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      createdAtFormattedDate != null
                          ? Text(
                              createdAtFormattedDate!,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            )
                          : Container(),
                      formattedReceiveAmount != null
                          ? Text(
                              formattedReceiveAmount! + ' ' + receiveAmountCrypto,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  ),
                            )
                          : Container(),
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

  Color _statusColor(BuildContext context, TradeState status) {
    switch (status) {
      case TradeState.complete:
      case TradeState.completed:
      case TradeState.finished:
      case TradeState.success:
      case TradeState.settled:
        return PaletteDark.brightGreen;
      case TradeState.failed:
      case TradeState.expired:
      case TradeState.notFound:
        return Palette.darkRed;
      default:
        return const Color(0xffff6600);
    }
  }
}
