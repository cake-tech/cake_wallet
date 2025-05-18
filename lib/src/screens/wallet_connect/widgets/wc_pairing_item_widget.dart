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
      leading: CakeImageWidget(
        imageUrl: metadata.icons.isNotEmpty ?  metadata.icons[0]: null,
        displayOnError: CircleAvatar(
          backgroundImage: AssetImage('assets/images/walletconnect_logo.png'),
        ),
      ),
      title: Text(
        metadata.name,
        style: TextStyle(
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
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(
            '${S.current.expiresOn}: $expiryDate',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      trailing: Container(
        height: 40,
        width: 44,
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
      onTap: onTap,
    );
  }
}
