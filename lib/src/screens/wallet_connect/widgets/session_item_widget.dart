import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:flutter/material.dart';
import 'package:wallet_connect_v2/wallet_connect_v2.dart';

class SessionItemWidget extends StatelessWidget {
  const SessionItemWidget({required this.session, required this.onTap, super.key});

  final Session session;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    AppMetadata? metadata = session.peer;
    
    DateTime dateTime = session.expiration;

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
