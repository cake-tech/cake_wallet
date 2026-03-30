import 'package:cake_wallet/new-ui/widgets/new_primary_button.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';

class LiveDemoWelcomeSheet extends StatelessWidget {
  const LiveDemoWelcomeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18))
      ),
      child: SafeArea(
        top: false,
        child: Column(mainAxisSize:MainAxisSize.min,children: [
          ModalTopBar(title: "", trailingIcon: Icon(Icons.close), onTrailingPressed: Navigator.of(context).pop, padding: EdgeInsets.only(top: 12,right: 12),),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Column(
              spacing: 12,
              children: [
              Text("Welcome! 🍰 ❤️", style: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),),
              Text("Cake Wallet is a non-custodial, open source Bitcoin wallet for mobile and desktop alike."),
              Text("Be sure to check out our features:\n\n- Try tapping the switch at the top to go to Lightning Mode!\n\n- Tap the three dot icon on the card to customize it."),
              SizedBox(),
              NewPrimaryButton(onPressed: Navigator.of(context).pop, text: "Get Started", color: Theme.of(context).colorScheme.primary, textColor: Theme.of(context).colorScheme.onPrimary)
            ],),
          )
        ],),
      ),
    );
  }
}
