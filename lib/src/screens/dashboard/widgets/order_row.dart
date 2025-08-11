import 'package:cake_wallet/exchange/trade_state.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class OrderRow extends StatelessWidget {
  const OrderRow({
    Key? key,
    required this.providerTitle,
    required this.providerIconPath,
    required this.from,
    required this.to,
    required this.createdAtFormattedDate,
    this.state,
    this.onTap,
    this.formattedAmount,
    this.formattedReceiveAmount,
  }) : super(key: key);

  final VoidCallback? onTap;

  final String providerTitle;
  final String providerIconPath;

  final String from;
  final String to;
  final String? createdAtFormattedDate;
  final String? formattedAmount;
  final String? formattedReceiveAmount;
  final TradeState? state;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
        color: Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                _ProviderIcon(path: providerIconPath, title: providerTitle),
                if (state != null)
                Positioned(
                  right: 0,
                  bottom: 2,
                  child: Container(
                    height: 8,
                    width: 8,
                    decoration: BoxDecoration(
                      color: _statusColor(context, state!),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '$from → $to',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                      ),
                      if (formattedAmount != null)
                        Text(
                          '${formattedAmount!} $from',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      if (createdAtFormattedDate != null)
                        Text(
                          createdAtFormattedDate!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      if (formattedReceiveAmount != null)
                        Text(
                          formattedReceiveAmount!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w500,
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

class _ProviderIcon extends StatelessWidget {
  const _ProviderIcon({required this.path, required this.title});

  final String path;
  final String title;

  @override
  Widget build(BuildContext context) {
    if (path.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(50),
        child: ImageUtil.getImageFromPath(imagePath: path, height: 36, width: 36),
      );
    }
    return Container(
      height: 36,
      width: 36,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(50),
        color: Theme.of(context).colorScheme.surfaceVariant,
      ),
      alignment: Alignment.center,
      child: Text(
        title.isNotEmpty ? title.characters.first.toUpperCase() : '?',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
