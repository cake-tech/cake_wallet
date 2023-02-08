import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu_item.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.topItems,
    required this.bottomItems,
  });
  final List<SideMenuItem> topItems;
  final List<SideMenuItem> bottomItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      width: 76,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          SizedBox(height: 20),
          ...topItems,
          Spacer(),
          ...bottomItems,
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
