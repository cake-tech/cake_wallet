import 'package:flutter/material.dart';
import 'package:cake_wallet/palette.dart';

class StandartListRow extends StatelessWidget {
  StandartListRow({this.title, this.value, this.isDrawTop, this.isDrawBottom});

  final String title;
  final String value;
  final bool isDrawTop;
  final bool isDrawBottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        isDrawTop
        ? Container(
          width: double.infinity,
          height: 1,
          color: PaletteDark.walletCardTopEndSync,
        )
        : Offstage(),
        Container(
          width: double.infinity,
          color: PaletteDark.menuList,
          child: Padding(
            padding: const EdgeInsets.only(left: 24, top: 16, bottom: 16, right: 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: PaletteDark.walletCardText),
                      textAlign: TextAlign.left),
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(value,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white)),
                  )
                ]),
          ),
        ),
        isDrawBottom
        ? Container(
          width: double.infinity,
          height: 1,
          color: PaletteDark.walletCardTopEndSync,
        )
        : Offstage(),
      ],
    );
  }
}
