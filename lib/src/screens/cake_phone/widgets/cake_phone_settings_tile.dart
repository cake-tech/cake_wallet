import 'package:flutter/material.dart';

class CakePhoneSettingsTile extends StatelessWidget {
  const CakePhoneSettingsTile({Key key, @required this.value, this.title, this.onTap}) : super(key: key);

  final String title;
  final Widget value;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Text(
              title,
              style: TextStyle(
                color: Theme.of(context).accentTextTheme.subhead.color,
              ),
            ),
          Container(
            padding: const EdgeInsets.only(top: 8, bottom: 16),
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).accentTextTheme.title.backgroundColor,
                ),
              ),
            ),
            child: value,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
