import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class StandartListCard extends StatelessWidget {
  StandartListCard({this.id, this.create, this.pair, this.onTap});

  final String id;
  final String create;
  final String pair;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    final baseGradient = LinearGradient(colors: [
      Theme.of(context).primaryTextTheme.subtitle.color,
      Theme.of(context).primaryTextTheme.subtitle.decorationColor,
    ], begin: Alignment.centerLeft, end: Alignment.centerRight);

    final textColor = Colors.white;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15.0),
              gradient: baseGradient),
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(id,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 16,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          color: textColor)),
                  SizedBox(
                    height: 8,
                  ),
                  Text(create,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 12,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.w400,
                          color: textColor)),
                  SizedBox(
                    height: 35,
                  ),
                  Text(pair,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          fontSize: 24,
                          fontFamily: 'Lato',
                          fontWeight: FontWeight.bold,
                          color: textColor)),
                ]),
          ),
        ),
      ),
    );
  }
}
