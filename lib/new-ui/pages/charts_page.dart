import 'package:cake_wallet/new-ui/viewmodels/charts/charts_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/asset_grid.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/asset_grid_header.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/chart_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChartsPage extends StatelessWidget {
  const ChartsPage({super.key, required this.chartsBloc});

  final ChartsBloc chartsBloc;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
  create: (context) => chartsBloc,
  child: BlocBuilder<ChartsBloc, ChartsState>(
  builder: (context, state) {
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
          child: Column(
            spacing: 24,
            children: [
              ChartHeader(),
              ChartsAssetGridHeader(
                onAddButtonPressed: () {},
                onSortButtonPressed: () {},
              ),
              Expanded(child: ChartsAssetGrid())
            ],
          ),
        ),
      ),
    );
  },
),
);
  }
}
