import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/page_open_listener.dart";
import "package:cake_wallet/new-ui/viewmodels/charts/charts_bloc.dart";
import "package:cake_wallet/new-ui/widgets/charts_page/asset_grid.dart";
import "package:cake_wallet/new-ui/widgets/charts_page/asset_grid_header.dart";
import "package:cake_wallet/new-ui/widgets/charts_page/chart_header.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/foundation.dart";
import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class ChartsPage extends StatelessWidget implements PageOpenListener {
  const ChartsPage({required this.chartsBloc, super.key});

  final ChartsBloc chartsBloc;

  @override
  void onPageOpen() {
    chartsBloc.add(Init());
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<ChartsBloc, ChartsState>(
        bloc: chartsBloc,
        builder: (context, state) {
          if (state is ChartsInitial) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 24,
                children: [
                  CakeImageWidget(
                    width: 36,
                    height: 36,
                    imageUrl: "assets/new-ui/navbar/charts.svg",
                  ),
                  CupertinoActivityIndicator(),
                  if (kDebugMode)
                    Text(
                      "devs: if this doesn't go away in a few seconds, either your device is painfully slow or the db is messed up",
                    ),
                ],
              ),
            );
          }

          if (state is ChartsDisabled) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                spacing: 12,
                children: [
                  CakeImageWidget(
                    width: 36,
                    height: 36,
                    imageUrl: "assets/new-ui/navbar/charts.svg",
                  ),
                  Text(
                    S.of(context).charts_unavailable,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w600),
                  ),
                  Text(S.of(context).charts_unavailable_desc),
                ],
              ),
            );
          }

          return Container(
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
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top),
                  sliver: CupertinoSliverRefreshControl(
                    refreshTriggerPullDistance: 160,
                    refreshIndicatorExtent: 90,
                    onRefresh: () async => chartsBloc.add(PageRefreshed()),
                  ),
                ),
                SliverToBoxAdapter(
                  child: SafeArea(
                    child: Column(
                      spacing: 24,
                      children: [
                        if (state is ChartsStateWithData)
                          ChartHeader(
                            bloc: chartsBloc,
                            currency: state.pinnedCurrency,
                            chartHeight: 100,
                            chartPadding: 22,
                            centered: false,
                            favorite: true,
                          ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Column(
                            spacing: 24,
                            children: [ChartsAssetGridHeader(bloc: chartsBloc), ChartsAssetGrid(bloc: chartsBloc)],
                          ),
                        ),
                        const SizedBox(
                          height: 96,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}
