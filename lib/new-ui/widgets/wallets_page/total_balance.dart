import 'package:flutter/material.dart';

class TotalBalanceWidget extends StatelessWidget {
  const TotalBalanceWidget({super.key, required this.totalBalance, required this.currency});

  final String totalBalance;
  final String currency;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Column(
          children: [
            Text("Total assets"),
            Row(
              children: [Text(totalBalance), Text(currency)],
            )
          ],
        )
      ],
    );
  }
}
