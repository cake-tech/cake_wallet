import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:flutter/material.dart';
import 'package:walletconnect_flutter_v2/apis/core/pairing/utils/pairing_models.dart';

class PairingItemWidget extends StatelessWidget {
  const PairingItemWidget({required this.pairing, required this.onTap, super.key});

  final PairingInfo pairing;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    PairingMetadata? metadata = pairing.peerMetadata;
    if (metadata == null) {
      return const ListTile(
        title: Text('Unknown'),
        subtitle: Text('No metadata available'),
      );
    }

    DateTime dateTime = DateTime.fromMillisecondsSinceEpoch(pairing.expiry * 1000);
    int year = dateTime.year;
    int month = dateTime.month;
    int day = dateTime.day;

    String expiryDate =
        '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: (metadata.icons.isNotEmpty
            ? NetworkImage(metadata.icons[0])
            : const AssetImage(
                'assets/images/default_icon.png',
              )) as ImageProvider<Object>,
      ),
      title: Text(
        metadata.name,
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.w700,
          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
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
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
          ),
          Text(
            'Expires on: $expiryDate',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
            ),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 20.0),
      onTap: onTap,
    );
  }
}
