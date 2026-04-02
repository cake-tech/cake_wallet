import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/viewmodels/charts_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/asset_grid.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/chart_view.dart';
import 'package:cake_wallet/new-ui/widgets/modern_button.dart';
import 'package:flutter/material.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key, required this.chartsBloc});

  final ChartsBloc chartsBloc;

  @override
  Widget build(BuildContext context) {
    return Container(
        height: MediaQuery.of(context).size.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceDim,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),

    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18.0),
        child: Column(spacing:24, children: [
        ChartHeader(),
          ChartsAssetGridHeader(onAddButtonPressed: (){},onSortButtonPressed: (){},),
          ChartsAssetGrid()
        ],),
      ),
    ),
    );
  }
}

class ChartsAssetGridHeader extends StatelessWidget {
  const ChartsAssetGridHeader({super.key, required this.onAddButtonPressed, required this.onSortButtonPressed});

  final VoidCallback onAddButtonPressed;
  final VoidCallback onSortButtonPressed;

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween,children: [
      Text(S.of(context).followed_assets, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 12)),
      Row(spacing:8,children: [
        ModernButton.svg(size: 36, iconSize: 16,svgPath: "assets/new-ui/add.svg",onPressed: onAddButtonPressed,),
        ModernButton.svg(size: 36, iconSize: 16,svgPath: "assets/new-ui/sort.svg",onPressed: onSortButtonPressed,)

      ],)
    ],);
  }
}

