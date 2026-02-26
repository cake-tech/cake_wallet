import 'package:cake_wallet/new-ui/widgets/modal_header.dart';
import 'package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:modal_bottom_sheet/modal_bottom_sheet.dart';

void nothing(){}

class ModalPageWrapper extends StatelessWidget {
  ModalPageWrapper(
      {super.key,
      required this.content,
      required this.topBar,
        this.header,
      this.horizontalPadding = 18.0,
      this.verticalPadding = 72.0}) {
  }

  final Widget content;
  final ModalTopBar topBar;
  final ModalHeader? header;
  final double horizontalPadding;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).colorScheme.surface,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            child: Padding(
                padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                  child: CustomScrollView(
                    controller: ModalScrollController.of(context),
                    physics: ClampingScrollPhysics(),
                    slivers: [
                      SliverToBoxAdapter(child: SizedBox(height: verticalPadding)),
                      if (header != null) ...[
                        SliverToBoxAdapter(child: header),
                        SliverToBoxAdapter(child: SizedBox(height: 20)),
                      ],
                      SliverSafeArea(sliver: SliverToBoxAdapter(child: content)),
                      SliverToBoxAdapter(child: SizedBox(height: verticalPadding)),
                    ],
                  )
                )),
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
