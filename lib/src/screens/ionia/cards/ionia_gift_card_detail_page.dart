import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_alert_model.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_tile.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_bar.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/utils/route_aware.dart';
import 'package:cake_wallet/view_model/ionia/ionia_gift_card_details_view_model.dart';
import 'package:device_display_brightness/device_display_brightness.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class IoniaGiftCardDetailPage extends BasePage {
  IoniaGiftCardDetailPage(this.viewModel);

  final IoniaGiftCardDetailsViewModel viewModel;

  @override
  Widget? leading(BuildContext context) {
    if (ModalRoute.of(context)!.isFirst) {
      return null;
    }

    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      size: 16,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: TextButton(
              // FIX-ME: Style
              //highlightColor: Colors.transparent,
              //splashColor: Colors.transparent,
              //padding: EdgeInsets.all(0),
              onPressed: ()=> onClose(context),
              child: _backButton),
        ),
      ),
    );
  }

  @override
  Widget middle(BuildContext context) {
    return Text(
      viewModel.giftCard.legalName,
      style: textMediumSemiBold(
          color: Theme.of(context).extension<CakeTextTheme>()!.titleColor),
    );
  }

  @override
  Widget body(BuildContext context) {
    reaction((_) => viewModel.redeemState, (ExecutionState state) {
      if (state is FailureState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          showPopUp<void>(
              context: context,
              builder: (BuildContext context) {
                return AlertWithOneAction(
                    alertTitle: S.of(context).error,
                    alertContent: state.error,
                    buttonText: S.of(context).ok,
                    buttonAction: () => Navigator.of(context).pop());
              });
        });
      }
    });

    return RouteAwareWidget(
        pushToWidget: ()=> viewModel.increaseBrightness(),
        pushToNextWidget: ()=> DeviceDisplayBrightness.setBrightness(viewModel.brightness),
        popNextWidget: ()=> viewModel.increaseBrightness(),
        popWidget: ()=> DeviceDisplayBrightness.setBrightness(viewModel.brightness),
      child: ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        children: [
          if (viewModel.giftCard.barcodeUrl != null && viewModel.giftCard.barcodeUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24,
              ),
              child: Image.network(viewModel.giftCard.barcodeUrl),
            ),
          SizedBox(height: 24),
          buildIoniaTile(
            context,
            title: S.of(context).gift_card_number,
            subTitle: viewModel.giftCard.cardNumber,
          ),
          if (viewModel.giftCard.cardPin.isNotEmpty) ...[
            Divider(height: 30),
            buildIoniaTile(
              context,
              title: S.of(context).pin_number,
              subTitle: viewModel.giftCard.cardPin,
            )
          ],
          Divider(height: 30),
          Observer(
              builder: (_) => buildIoniaTile(
                    context,
                    title: S.of(context).amount,
                    subTitle: viewModel.remainingAmount.toStringAsFixed(2),
                  )),
          Divider(height: 50),
          TextIconButton(
            label: S.of(context).how_to_use_card,
            onTap: () => _showHowToUseCard(context, viewModel.giftCard),
          ),
        ],
      ),
      bottomSection: Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Observer(
          builder: (_) {
            if (!viewModel.giftCard.isEmpty) {
              return Column(
                children: [
                  PrimaryButton(
                    onPressed: () async {
                       await Navigator.of(context).pushNamed(
                          Routes.ioniaMoreOptionsPage,
                          arguments: [viewModel.giftCard]) as String?;
                        viewModel.refeshCard();
                    },
                    text: S.of(context).more_options,
                    color: Theme.of(context).cardColor,
                    textColor: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
                  ),
                  SizedBox(height: 12),
                  LoadingPrimaryButton(
                    isLoading: viewModel.redeemState is IsExecutingState,
                    onPressed: () => viewModel.redeem().then(
                      (_) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                            Routes.ioniaManageCardsPage, (route) => route.isFirst);
                      },
                    ),
                    text: S.of(context).mark_as_redeemed,
                    color: Theme.of(context).primaryColor,
                    textColor: Colors.white,
                  ),
                ],
              );
            }

            return Container();
          },
        ),
      ),
    ));
  }

  Widget buildIoniaTile(BuildContext context, {required String title, required String subTitle}) {
    return IoniaTile(
        title: title,
        subTitle: subTitle,
        onTap: () {
          Clipboard.setData(ClipboardData(text: subTitle));
          showBar<void>(context, S.of(context).transaction_details_copied(title));
        });
  }

  void _showHowToUseCard(
    BuildContext context,
    IoniaGiftCard merchant,
  ) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return IoniaAlertModal(
            title: S.of(context).how_to_use_card,
            content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: viewModel.giftCard.instructions
                    .map((instruction) {
                      return [
                        Padding(
                            padding: EdgeInsets.all(10),
                            child: Text(
                              instruction.header,
                              style: textLargeSemiBold(
                                color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                              ),
                            )),
                        Text(
                          instruction.body,
                          style: textMedium(
                            color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                          ),
                        )
                      ];
                    })
                    .expand((e) => e)
                    .toList()),
            actionTitle: S.of(context).got_it,
          );
        });
  }
}
