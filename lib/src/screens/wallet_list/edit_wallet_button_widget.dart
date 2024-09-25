import 'package:cake_wallet/themes/extensions/filter_theme.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:flutter/material.dart';

class EditWalletButtonWidget extends StatelessWidget {
  const EditWalletButtonWidget({
    required this.width,
    required this.onTap,
    this.isGroup = false,
    super.key,
  });

  final bool isGroup;
  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      child: Row(
        children: [
          GestureDetector(
            onTap: onTap,
            child: Center(
              child: Container(
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
            ),
          ),
          if (isGroup) ...{
            SizedBox(width: 6),
            Icon(
              Icons.keyboard_arrow_down,
              size: 24,
              color: Theme.of(context).extension<FilterTheme>()!.titlesColor,
            ),
          },
        ],
      ),
    );
  }
}
