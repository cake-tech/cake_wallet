import 'package:flutter/cupertino.dart';

class NavBar extends StatelessWidget implements ObstructingPreferredSizeWidget {
  factory NavBar({Widget? leading, Widget? middle, Widget? trailing, Color? backgroundColor}) {
    return NavBar._internal(
        leading: leading,
        middle: middle,
        trailing: trailing,
        height: _height,
        backgroundColor: backgroundColor);
  }

  factory NavBar.withShadow(
      {Widget? leading, Widget? middle, Widget? trailing, Color? backgroundColor}) {
    return NavBar._internal(
      leading: leading,
      middle: middle,
      trailing: trailing,
      height: 80,
      backgroundColor: backgroundColor,
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: [
          BoxShadow(
            color: Color.fromRGBO(132, 141, 198, 0.11),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
    );
  }

  NavBar._internal(
      {this.leading,
      this.middle,
      this.trailing,
      this.backgroundColor,
      this.decoration,
      this.height = _height});

  static const _originalHeight = 44.0; // iOS nav bar height
  static const _height = 60.0;

  final Widget? leading;
  final Widget? middle;
  final Widget? trailing;
  final Color? backgroundColor;
  final BoxDecoration? decoration;
  final double height;

  @override
  Widget build(BuildContext context) {
    if (leading == null && middle == null && trailing == null) {
      return const SizedBox();
    }

    final pad = height - _originalHeight;
    final paddingTop = pad / 2;
    final _paddingBottom = (pad / 2);

    return Container(
      decoration: decoration ?? BoxDecoration(color: backgroundColor),
      padding: EdgeInsetsDirectional.only(bottom: _paddingBottom, top: paddingTop),
      child: CupertinoNavigationBar(
        leading: leading,
        automaticallyImplyLeading: false,
        automaticallyImplyMiddle: false,
        transitionBetweenRoutes: false,
        middle: middle,
        trailing: trailing,
        backgroundColor: backgroundColor,
        border: null,
      ),
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(height);

  @override
  bool shouldFullyObstruct(BuildContext context) {
    return false;
  }
}
