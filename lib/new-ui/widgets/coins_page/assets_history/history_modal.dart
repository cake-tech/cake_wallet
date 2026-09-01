import "package:cake_wallet/core/csv_export_service.dart";
import "package:cake_wallet/di.dart";
import "package:cake_wallet/generated/i18n.dart";
import "package:cake_wallet/new-ui/viewmodels/transaction_history/transaction_history_bloc.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_filters_page.dart";
import "package:cake_wallet/new-ui/widgets/coins_page/assets_history/history_section.dart";
import "package:cake_wallet/new-ui/widgets/receive_page/receive_top_bar.dart";
import "package:cake_wallet/src/widgets/cake_image_widget.dart";
import "package:flutter/cupertino.dart";
import "package:flutter/material.dart";
import "package:modal_bottom_sheet/modal_bottom_sheet.dart";

class HistoryModal extends StatelessWidget {
  const HistoryModal({super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
        ),
        child: Column(
          children: [
            ModalTopBar(
              title: S.of(context).history,
              leadingIcon: const Icon(Icons.close),
              leadingSemanticLabel: S.of(context).close,
              onLeadingPressed: Navigator.of(context).maybePop,
              trailingIcon: CakeImageWidget(
                imageUrl: "assets/new-ui/tx_export.svg",
                colorFilter:
                    ColorFilter.mode(Theme.of(context).colorScheme.primary, BlendMode.srcIn),
              ),
              trailingSemanticLabel: S.of(context).export_csv,
              onTrailingPressed: () {
                final state = getIt.get<TransactionHistoryBloc>().state;

                CsvExportService().exportToCsv(
                  state is TransactionHistoryLoaded ? state.items : const [],
                  context,
                );
              },
            ),
            Expanded(
              child: Stack(
                children: [
                  Material(
                    child: CustomScrollView(
                      physics: const ClampingScrollPhysics(),
                      controller: ModalScrollController.of(context),
                      slivers: [
                        getIt.get<HistorySection>(
                          param1: const HistorySectionArguments(
                            detailsAsPage: true,
                            short: false,
                            roundedTopSection: true,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Material(
                      color: Colors.transparent,
                      child: Container(
                        height: MediaQuery.of(context).viewPadding.bottom + 168,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: <Color>[
                              Theme.of(context).colorScheme.surface.withAlpha(200),
                              Theme.of(context).colorScheme.surface.withAlpha(175),
                              Theme.of(context).colorScheme.surface.withAlpha(150),
                              Theme.of(context).colorScheme.surface.withAlpha(100),
                              Theme.of(context).colorScheme.surface.withAlpha(50),
                              Theme.of(context).colorScheme.surface.withAlpha(25),
                              Theme.of(context).colorScheme.surface.withAlpha(5),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    left: 12,
                    right: 12,
                    bottom: MediaQuery.of(context).viewPadding.bottom + 24,
                    child: Material(
                      borderRadius: BorderRadius.circular(18),
                      color: Theme.of(context).colorScheme.surfaceContainer,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          await Navigator.of(context).push(
                            CupertinoPageRoute(
                              builder: (context) =>
                                  HistoryFiltersPage(bloc: getIt.get<TransactionHistoryBloc>()),
                            ),
                          );

                          getIt
                              .get<TransactionHistoryBloc>()
                              .add(const TransactionHistoryRefreshed());
                        },
                        child: Material(
                          color: Colors.transparent,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Theme.of(context).colorScheme.primary,
                                width: 1,
                              ),
                            ),
                            height: 56,
                            width: double.infinity,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              spacing: 10,
                              children: [
                                CakeImageWidget(
                                  imageUrl: "assets/new-ui/filter_options.svg",
                                  colorFilter: ColorFilter.mode(
                                    Theme.of(context).colorScheme.primary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                Text(
                                  S.of(context).filters,
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Theme.of(context).colorScheme.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
