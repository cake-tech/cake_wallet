import 'package:flutter/material.dart';

class ReceiveSeedWidget extends StatelessWidget {
  const ReceiveSeedWidget({super.key});

  static const List<String> dummyWalletStrings = [
    'bc1q',
    'xy2k',
    'gdyg',
    'jrsq',
    'tzq2',
    'n0yr',
    'f249',
    '3p83',
    'kkfj',
    'hx0wlh',
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 80.0),
      child: Wrap(
        alignment: WrapAlignment.center,
        spacing: 8.0,
        runSpacing: 4.0,
        children: List.generate(
          dummyWalletStrings.length,
          (index) => Text(
            dummyWalletStrings[index],
            style: TextStyle(
              fontSize: 16,
              color: index % 2 != 0 ? Colors.grey : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
