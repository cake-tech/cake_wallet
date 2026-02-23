import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';

void nothing(){}

class ModalPageWrapper extends StatelessWidget {
  ModalPageWrapper(
      {super.key,
      required this.content,
      required this.topBar}) {
  }

  static const boxHeight = 64.0;

  final ModalTopBar topBar;
  final Widget content;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          content,
          Container(
            height: (MediaQuery.of(context).padding.top + 84),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: <Color>[
                  Theme.of(context).colorScheme.surface.withAlpha(5),
                  Theme.of(context).colorScheme.surface.withAlpha(25),
                  Theme.of(context).colorScheme.surface.withAlpha(50),
                  Theme.of(context).colorScheme.surface.withAlpha(100),
                  Theme.of(context).colorScheme.surface.withAlpha(150),
                  Theme.of(context).colorScheme.surface.withAlpha(200),
                  Theme.of(context).colorScheme.surface.withAlpha(235),
                  Theme.of(context).colorScheme.surface.withAlpha(255),
                  Theme.of(context).colorScheme.surface.withAlpha(255),
                  Theme.of(context).colorScheme.surface.withAlpha(255),
                ],
              ),
            ),
          ),
          topBar,
        ],
      ),
    );
  }
}
