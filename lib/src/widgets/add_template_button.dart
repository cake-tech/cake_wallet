import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/utils/responsive_layout_util.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';

class AddTemplateButton extends StatelessWidget {
  final Function() onTap;
  final int currentTemplatesLength;

  const AddTemplateButton({Key? key, required this.onTap, required this.currentTemplatesLength})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(left: 1, right: 10),
        child: DottedBorder(
          borderType: BorderType.RRect,
          dashPattern: [6, 4],
          color: Theme.of(context).primaryTextTheme.headline3!.decorationColor!,
          strokeWidth: 2,
          radius: Radius.circular(20),
          child: Container(
            height: 34,
            padding: EdgeInsets.symmetric(
                horizontal: ResponsiveLayoutUtil.instance.isMobile(context) ? 10 : 30),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.all(Radius.circular(20)),
              color: Colors.transparent,
            ),
            child: currentTemplatesLength >= 1
                ? Icon(
                    Icons.add,
                    color: Theme.of(context).primaryTextTheme.headline2!.color!,
                  )
                : Text(
                    S.of(context).new_template,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).primaryTextTheme.headline2!.color!,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
