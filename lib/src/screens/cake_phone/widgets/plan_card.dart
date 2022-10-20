import 'package:cake_wallet/entities/cake_phone_entities/service_plan.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';

class PlanCard extends StatelessWidget {
  const PlanCard({Key key, @required this.plan, @required this.onTap, this.isSelected = false}) : super(key: key);

  final ServicePlan plan;
  final bool isSelected;
  final Function() onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          gradient: isSelected
              ? LinearGradient(
            colors: [
              Theme.of(context).primaryTextTheme.subtitle1!.color!,
              Theme.of(context).primaryTextTheme.subtitle1!.decorationColor!,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
              : null,
          color: isSelected ? null : Theme.of(context).primaryTextTheme.displayMedium?.decorationColor,
        ),
        child: Column(
          children: [
            Text(
              "\$${plan.price}/${S.of(context).month}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
            Text(
              "${plan.duration} ${S.of(context).month}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).accentTextTheme.subtitle1?.color,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
