import 'package:cake_wallet/entities/bridge_transfer.dart';
import 'package:cake_wallet/evm/evm.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/core/custom_theme_colors.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransferHistoryRow extends StatelessWidget {
  const TransferHistoryRow({
    required this.transfer,
    required this.onTap,
    super.key,
  });

  final BridgeTransfer transfer;
  final VoidCallback onTap;

  String _statusLabel(String status) {
    switch (status) {
      case 'submitted':
        return "Submitted";
      case 'confirming':
        return "Confirming on source";
      case 'initiated':
        return "Bridge initiated";
      case 'completed':
        return "Completed";
      case 'failed':
        return "Failed";
      default:
        return status;
    }
  }

  Color _statusColor(BuildContext context, String status) {
    switch (status) {
      case 'completed':
        return CustomThemeColors.syncGreen;
      case 'failed':
        return Theme.of(context).colorScheme.error;
      case 'submitted':
      case 'confirming':
      case 'initiated':
      default:
        return CustomThemeColors.syncYellow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final sourceChainName = evm?.getChainInfoByChainId(transfer.sourceChainId)?.name;
    final destChainName = evm?.getChainInfoByChainId(transfer.destinationChainId)?.name;
    final formattedDate = DateFormat('HH:mm').format(transfer.createdAt);
    final statusText = _statusLabel(transfer.status);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        margin: const EdgeInsets.only(bottom: 16),
        width: double.infinity,
        height: 72,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surfaceContainerHigh,
              Theme.of(context).colorScheme.surfaceContainer,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.all(Radius.circular(20)),
          border: Border.all(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              height: 42,
              width: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  CakeImageWidget(
                    imageUrl:
                        'assets/new-ui/crypto_full_icons/${sourceChainName?.toLowerCase()}.svg',
                    width: 28,
                    height: 28,
                  ),
                  Positioned(
                    top: 14,
                    left: 12,
                    child: CakeImageWidget(
                      imageUrl:
                          'assets/new-ui/crypto_full_icons/${destChainName?.toLowerCase()}.svg',
                      width: 28,
                      height: 28,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        '$sourceChainName → $destChainName',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                      Text(
                        '${transfer.amount} ${transfer.tokenSymbol}',
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Row(
                        children: [
                          Container(
                            height: 8,
                            width: 8,
                            decoration: BoxDecoration(
                              color: _statusColor(context, transfer.status),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.surface,
                                width: 1.5,
                              ),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            statusText,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w500,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      Text(
                        formattedDate,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
