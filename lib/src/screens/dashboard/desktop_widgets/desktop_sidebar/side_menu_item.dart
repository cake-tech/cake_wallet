import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu_controller.dart';
import 'package:flutter/material.dart';

class SideMenuItem extends StatefulWidget {
  const SideMenuItem({
    Key? key,
    this.onTap,
    required this.iconPath,
    required this.priority,
  }) : super(key: key);

  final void Function(int, SideMenuController)? onTap;
  final String iconPath;
  final int priority;

  @override
  _SideMenuItemState createState() => _SideMenuItemState();
}

class _SideMenuItemState extends State<SideMenuItem> {
  late int currentPage = SideMenuGlobal.controller.currentPage;

  void _handleChange(int page) {
    if (mounted) {
      setState(() {
        currentPage = page;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((timeStamp) {
      setState(() {
        currentPage = SideMenuGlobal.controller.currentPage;
      });
      if (mounted) {
        SideMenuGlobal.controller.addListener(_handleChange);
      }
    });
  }

  @override
  void dispose() {
    SideMenuGlobal.controller.removeListener(_handleChange);
    super.dispose();
  }

  Color _setColor() {
    if (widget.priority == currentPage) {
      return Theme.of(context).primaryTextTheme.headline6!.color!;
    } else {
      return Theme.of(context).highlightColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      child: Padding(
        padding: EdgeInsets.all(20),
        child: Image.asset(
          widget.iconPath,
          fit: BoxFit.cover,
          height: 30,
          width: 30,
          color: _setColor(),
        ),
      ),
      onTap: () => widget.onTap?.call(widget.priority, SideMenuGlobal.controller),
      highlightColor: Colors.transparent,
      focusColor: Colors.transparent,
      hoverColor: Colors.transparent,
      splashColor: Colors.transparent,
    );
  }
}
