import 'package:flutter/material.dart';

import 'navbar_button.dart';

class Navbar extends StatefulWidget {
  const Navbar({super.key});

  @override
  State<Navbar> createState() => _NavbarState();
}

class NavbarItemData {
  final String iconPath;
  final String text;

  NavbarItemData(this.iconPath, this.text);
}

class _NavbarState extends State<Navbar> {
  int _selectedIndex = 0;

  final List<NavbarItemData> _items = [
    NavbarItemData("assets/Home.svg", "Home"),
    NavbarItemData("assets/Wallets.svg", "Wallets"),
    NavbarItemData("assets/Contacts.svg", "Contacts"),
    NavbarItemData("assets/Apps.svg", "Apps"),
    NavbarItemData("assets/Charts.svg", "Charts"),
  ];

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(99999),
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withAlpha(170),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 12.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: List.generate(_items.length, (index) {
                return NavbarButton(
                  data: _items[index],
                  onPressed: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  selected: _selectedIndex == index,
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
