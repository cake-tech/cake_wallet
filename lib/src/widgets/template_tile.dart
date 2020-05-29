import 'package:flutter/material.dart';

class TemplateTile extends StatelessWidget {
  TemplateTile({
    @required this.to,
    @required this.amount,
    @required this.from,
    @required this.onTap
  });

  final String to;
  final String amount;
  final String from;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final toIcon = Image.asset('assets/images/to_icon.png',
      color: Theme.of(context).primaryTextTheme.title.color,
    );

    return Container(
      padding: EdgeInsets.only(right: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 40,
          padding: EdgeInsets.only(left: 24, right: 24),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: Theme.of(context).accentTextTheme.title.backgroundColor
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                amount,
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).primaryTextTheme.title.color
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  from,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: toIcon,
              ),
              Padding(
                padding: EdgeInsets.only(left: 5),
                child: Text(
                  to,
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.title.color
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}