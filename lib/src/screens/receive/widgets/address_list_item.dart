import 'package:auto_size_text/auto_size_text.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter/material.dart';

class AddressListItem extends StatelessWidget {
  AddressListItem({required this.address, required this.isChange});

  final String address;
  final bool isChange;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: 70, minHeight: 50),
      child: Container(
          padding: EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(12)),
              color: Theme.of(context).primaryColor),
          child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                AutoSizeText(
                  address,
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600),
                  maxLines: 1,
                ),
                if (isChange)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        height: 17,
                        padding: EdgeInsets.only(left: 6, right: 6),
                        decoration: BoxDecoration(
                            borderRadius:
                                BorderRadius.all(Radius.circular(8.5)),
                            color: Colors.white),
                        alignment: Alignment.center,
                        child: Text(
                          S.of(context).unspent_change,
                          style: TextStyle(
                            color: Theme.of(context).primaryColor,
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
              ])),
    );
  }
}
