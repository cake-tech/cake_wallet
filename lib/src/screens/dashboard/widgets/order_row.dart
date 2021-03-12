import 'package:flutter/material.dart';

class OrderRow extends StatelessWidget {
  OrderRow({
    @required this.onTap,
    this.from,
    this.to,
    this.createdAtFormattedDate,
    this.formattedAmount});
  final VoidCallback onTap;
  final String from;
  final String to;
  final String createdAtFormattedDate;
  final String formattedAmount;
  final wyreImage =
      Image.asset('assets/images/wyre-icon.png', width: 36, height: 36);

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.fromLTRB(24, 8, 24, 8),
          color: Colors.transparent,
          child: Row(
            mainAxisSize: MainAxisSize.max,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              wyreImage,
              SizedBox(width: 12),
              Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text('$from → $to',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                )),
                            formattedAmount != null
                                ? Text(formattedAmount + ' ' + to,
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).accentTextTheme.
                                    display3.backgroundColor
                                ))
                                : Container()
                          ]),
                      SizedBox(height: 5),
                      Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: <Widget>[
                            Text(createdAtFormattedDate,
                                style: TextStyle(
                                    fontSize: 14,
                                    color: Theme.of(context).textTheme
                                        .overline.backgroundColor))
                          ])
                    ],
                  )
              )
            ],
          ),
        ));
  }
}