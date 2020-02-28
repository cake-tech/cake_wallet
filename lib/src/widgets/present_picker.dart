import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:cake_wallet/generated/i18n.dart';

Future<T> presentPicker<T extends Object>(
    BuildContext context, List<T> list) async {
  T _value = list[0];

  return await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(S.of(context).please_select),
          backgroundColor: Theme.of(context).backgroundColor,
          content: Container(
            height: 150.0,
            child: CupertinoPicker(
                backgroundColor: Theme.of(context).backgroundColor,
                itemExtent: 45.0,
                onSelectedItemChanged: (int index) => _value = list[index],
                children: List.generate(
                    list.length,
                        (index) => Center(
                      child: Text(
                        list[index].toString(),
                        style: TextStyle(
                            color: Theme.of(context)
                                .primaryTextTheme
                                .caption
                                .color),
                      ),
                    ))),
          ),
          actions: <Widget>[
            FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(S.of(context).cancel)),
            FlatButton(
                onPressed: () => Navigator.of(context).pop(_value),
                child: Text(S.of(context).ok))
          ],
        );
      });
}