import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/cake_image_widget.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
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
          backgroundImage: AssetImage('assets/images/default_icon.png'),
        ),
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
            '${S.current.expiresOn}: $expiryDate',
            style: TextStyle(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: Theme.of(context).extension<CakeTextTheme>()!.secondaryTextColor,
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
          color: Theme.of(context).extension<ReceivePageTheme>()!.iconsBackgroundColor,
        ),
        child: Icon(
          Icons.edit,
          size: 14,
          color: Theme.of(context).extension<ReceivePageTheme>()!.iconsColor,
        ),
      ),
      onTap: onTap,
    );
  }
}
