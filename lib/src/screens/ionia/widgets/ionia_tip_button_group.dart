import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:cake_wallet/typography.dart';
import 'package:flutter/material.dart';

class IoniaTipButtonGroup extends StatelessWidget {
  const IoniaTipButtonGroup({
    Key key,
    @required this.selectedTip,
    @required this.onSelect,
    @required this.tipsList,
  }) : super(key: key);

  final Function(IoniaTip) onSelect;
  final double selectedTip;
  final List<IoniaTip> tipsList;

  bool _isSelected(double value) => selectedTip == value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...[
          for (var i = 0; i < tipsList.length; i++) ...[
            TipButton(
              isSelected: _isSelected(tipsList[i].percentage),
              onTap: () => onSelect(tipsList[i]),
              caption: '${tipsList[i].percentage}%',
              subTitle: '\$${tipsList[i].additionalAmount}',
            ),
            SizedBox(width: 4),
          ]
        ],
      ],
    );
  }
}

class TipButton extends StatelessWidget {
  const TipButton({
    @required this.caption,
    this.subTitle,
    @required this.onTap,
    this.isSelected = false,
  });

  final String caption;
  final String subTitle;
  final bool isSelected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 49,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(caption,
                style: textSmallSemiBold(
                    color: isSelected
                        ? Theme.of(context).accentTextTheme.title.color
                        : Theme.of(context).primaryTextTheme.title.color)),
            if (subTitle != null) ...[
              SizedBox(height: 4),
              Text(
                subTitle,
                style: textXxSmallSemiBold(
                  color: isSelected
                      ? Theme.of(context).accentTextTheme.title.color
                      : Theme.of(context).primaryTextTheme.overline.color,
                ),
              ),
            ]
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromRGBO(242, 240, 250, 1),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
      ),
    );
  }
}
