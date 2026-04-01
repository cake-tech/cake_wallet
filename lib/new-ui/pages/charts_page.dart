import 'package:cake_wallet/new-ui/viewmodels/charts_bloc.dart';
import 'package:cake_wallet/new-ui/widgets/charts_page/chart_view.dart';
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
        child: Column(children: [
        ChartHeader()
        ],),
      ),
    ),
    );
  }
}
