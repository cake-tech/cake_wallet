import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:flutter/material.dart';
import 'package:reown_walletkit/reown_walletkit.dart';

class WCPairingItemWidget extends StatelessWidget {
  const WCPairingItemWidget({required this.pairing, required this.onTap, super.key});

  final PairingInfo pairing;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    PairingMetadata? metadata = pairing.peerMetadata;

    if (metadata == null) {
      return SizedBox.shrink();
    }

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(pairing.expiry * 1000);
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;

    String expiryDate =
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: SizedBox(
        width: 60,
        height: 60,
        child: CakeImageWidget(
          borderRadius: 8,
          width: 60,
          height: 60,
          imageUrl: metadata.icons.isNotEmpty ? metadata.icons[0] : null,
          errorWidget: CircleAvatar(
            backgroundImage: AssetImage('assets/images/walletconnect_logo.png'),
          ),
        ),
      ),
      title: Text(
        metadata.name,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 16.0,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            metadata.url,
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          Text(
            '${S.current.expiresOn}: $expiryDate',
            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
      trailing: SizedBox(
        width: 44,
        height: 40,
        child: Container(
          padding: EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: Icon(
            Icons.edit,
            size: 14,
            color: Theme.of(context).colorScheme.onPrimary,
          ),
        ),
      ),
      onTap: onTap,
    );
  }
}
