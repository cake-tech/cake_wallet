import 'package:cake_wallet/src/screens/dashboard/desktop_widgets/desktop_sidebar/side_menu_item.dart';
import 'package:flutter/material.dart';

class SideMenu extends StatelessWidget {
  const SideMenu({
    super.key,
    required this.topItems,
    required this.bottomItems,
    required this.width,
  });
  
  final List<SideMenuItem> topItems;
  final List<SideMenuItem> bottomItems;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black.withOpacity(0.1),
      width: width,
      height: MediaQuery.of(context).size.height,
      child: Column(
        children: [
          ...topItems,
          Spacer(),
          ...bottomItems,
          SizedBox(height: 30),
        ],
      ),
    );
  }
}
