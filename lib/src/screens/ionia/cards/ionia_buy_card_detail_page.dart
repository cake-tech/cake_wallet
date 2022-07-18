import 'dart:ui';
import 'package:cake_wallet/anypay/any_pay_payment_committed_info.dart';
import 'package:cake_wallet/core/execution_state.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/ionia/ionia_tip.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/confirm_modal.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/discount_badge.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/widgets/standart_list_row.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_purchase_merch_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:mobx/mobx.dart';

class IoniaBuyGiftCardDetailPage extends StatelessWidget {
  IoniaBuyGiftCardDetailPage(this.ioniaPurchaseViewModel);

  final IoniaMerchPurchaseViewModel ioniaPurchaseViewModel;

  ThemeBase get currentTheme => getIt.get<SettingsStore>().currentTheme;

  Color get backgroundLightColor => Colors.white;

  Color get backgroundDarkColor => PaletteDark.backgroundColor;

  void onClose(BuildContext context) => Navigator.of(context).pop();

  Widget leading(BuildContext context) {
    if (ModalRoute.of(context).isFirst) {
      return null;
    }

    final _backButton = Icon(
      Icons.arrow_back_ios,
      color: Theme.of(context).primaryTextTheme.title.color,
      size: 16,
    );
    return Padding(
      padding: const EdgeInsets.only(left: 10.0),
      child: SizedBox(
        height: 37,
        width: 37,
        child: ButtonTheme(
          minWidth: double.minPositive,
          child: FlatButton(
              highlightColor: Colors.transparent,
              splashColor: Colors.transparent,
              padding: EdgeInsets.all(0),
              onPressed: () => onClose(context),
              child: _backButton),
        ),
      ),
    );
  }

  Widget middle(BuildContext context) {
    return Text(
      ioniaPurchaseViewModel.ioniaMerchant.legalName,
      style: textLargeSemiBold(color: Theme.of(context).accentTextTheme.display4.backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ioniaPurchaseViewModel.ioniaMerchant;
    final _backgroundColor = currentTheme.type == ThemeType.dark ? backgroundDarkColor : backgroundLightColor;

    reaction((_) => ioniaPurchaseViewModel.invoiceCreationState, (ExecutionState state) {
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

    reaction((_) => ioniaPurchaseViewModel.invoiceCommittingState, (ExecutionState state) {
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

      if (state is ExecutedSuccessfullyState) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed(
            Routes.ioniaPaymentStatusPage,
            arguments: [
              ioniaPurchaseViewModel.paymentInfo,
              ioniaPurchaseViewModel.committedInfo]);
        });
      }
    });

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.zero,
        content: Observer(builder: (_) {
          final tipAmount = ioniaPurchaseViewModel.tipAmount;
          return Column(
            children: [
              SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  leading(context),
                  middle(context),
                  DiscountBadge(
                    percentage: merchant.minimumDiscount,
                  )
                ],
              ),
              SizedBox(height: 36),
              Container(
                padding: EdgeInsets.symmetric(vertical: 24),
                margin: EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      Theme.of(context).primaryTextTheme.subhead.color,
                      Theme.of(context).primaryTextTheme.subhead.decorationColor,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  children: [
                    Text(
                      S.of(context).gift_card_amount,
                      style: textSmall(),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '\$${ioniaPurchaseViewModel.giftCardAmount}',
                      style: textXLargeSemiBold(),
                    ),
                    SizedBox(height: 24),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                S.of(context).bill_amount,
                                style: textSmall(),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$${ioniaPurchaseViewModel.amount}',
                                style: textLargeSemiBold(),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                S.of(context).tip,
                                style: textSmall(),
                              ),
                              SizedBox(height: 4),
                              Text(
                                '\$$tipAmount',
                                style: textLargeSemiBold(),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).tip,
                      style: TextStyle(
                        color: Theme.of(context).primaryTextTheme.title.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: 4),
                    Observer(
                      builder: (_) => TipButtonGroup(
                        selectedTip: ioniaPurchaseViewModel.selectedTip.percentage,
                        tipsList: ioniaPurchaseViewModel.tips,
                        onSelect: (value) => ioniaPurchaseViewModel.addTip(value),
                      ),
                    )
                  ],
                ),
              ),
              SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: TextIconButton(
                  label: S.of(context).how_to_use_card,
                  onTap: () => _showHowToUseCard(context, merchant),
                ),
              ),
            ],
          );
        }),
        bottomSection: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Observer(builder: (_) {
                return LoadingPrimaryButton(
                  isLoading: ioniaPurchaseViewModel.invoiceCreationState is IsExecutingState ||
                      ioniaPurchaseViewModel.invoiceCommittingState is IsExecutingState,
                  onPressed: () => purchaseCard(context),
                  text: S.of(context).purchase_gift_card,
                  color: Theme.of(context).accentTextTheme.body2.color,
                  textColor: Colors.white,
                );
              }),
            ),
            SizedBox(height: 8),
            InkWell(
              onTap: () => _showTermsAndCondition(context),
              child: Text(S.of(context).settings_terms_and_conditions,
                  style: textMediumSemiBold(
                    color: Theme.of(context).primaryTextTheme.body1.color,
                  ).copyWith(fontSize: 12)),
            ),
            SizedBox(height: 16)
          ],
        ),
      ),
    );
  }

  void _showTermsAndCondition(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: '',
          alertContent: ioniaPurchaseViewModel.ioniaMerchant.termsAndConditions,
          buttonText: S.of(context).agree,
          buttonAction: () => Navigator.of(context).pop(),
        );
      },
    );
  }

  Future<void> purchaseCard(BuildContext context) async {
    await ioniaPurchaseViewModel.createInvoice();

    if (ioniaPurchaseViewModel.invoiceCreationState is ExecutedSuccessfullyState) {
      await _presentSuccessfulInvoiceCreationPopup(context);
    }
  }

  void _showHowToUseCard(
    BuildContext context,
    IoniaMerchant merchant,
  ) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertBackground(
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(height: 10),
                  Container(
                    padding: EdgeInsets.only(top: 24, left: 24, right: 24),
                    margin: EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).backgroundColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Text(
                          S.of(context).how_to_use_card,
                          style: textLargeSemiBold(
                            color: Theme.of(context).textTheme.body1.color,
                          ),
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            merchant.usageInstructionsBak,
                            style: textMedium(
                              color: Theme.of(context).textTheme.display2.color,
                            ),
                          ),
                        ),
                        SizedBox(height: 35),
                        PrimaryButton(
                          onPressed: () => Navigator.pop(context),
                          text: S.of(context).send_got_it,
                          color: Color.fromRGBO(233, 242, 252, 1),
                          textColor: Theme.of(context).textTheme.display2.color,
                        ),
                        SizedBox(height: 21),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 40),
                      child: CircleAvatar(
                        child: Icon(
                          Icons.close,
                          color: Colors.black,
                        ),
                        backgroundColor: Colors.white,
                      ),
                    ),
                  )
                ],
              ),
            ),
          );
        });
  }

  Future<void> _presentSuccessfulInvoiceCreationPopup(BuildContext context) async {
    final amount = ioniaPurchaseViewModel.invoice.totalAmount;
    final addresses = ioniaPurchaseViewModel.invoice.outAddresses;

    await showPopUp<void>(
      context: context,
      builder: (_) {
        return IoniaConfirmModal(
            alertTitle: S.of(context).confirm_sending,
            alertContent: Container(
                height: 200,
                padding: EdgeInsets.all(15),
                child: Column(children: [
                  Row(children: [
                    Text(S.of(context).payment_id,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: PaletteDark.pigeonBlue,
                            decoration: TextDecoration.none)),
                    Text(ioniaPurchaseViewModel.invoice.paymentId,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: PaletteDark.pigeonBlue,
                            decoration: TextDecoration.none))
                  ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
                  SizedBox(height: 10),
                  Row(children: [
                    Text(S.of(context).amount,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: PaletteDark.pigeonBlue,
                            decoration: TextDecoration.none)),
                    Text('$amount ${ioniaPurchaseViewModel.invoice.chain}',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: PaletteDark.pigeonBlue,
                            decoration: TextDecoration.none))
                  ], mainAxisAlignment: MainAxisAlignment.spaceBetween),
                  SizedBox(height: 25),
                  Row(children: [
                    Text(S.of(context).recipient_address,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: PaletteDark.pigeonBlue,
                            decoration: TextDecoration.none))
                  ], mainAxisAlignment: MainAxisAlignment.center),
                  Expanded(
                      child: ListView.builder(
                          itemBuilder: (_, int index) {
                            return Text(addresses[index],
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: PaletteDark.pigeonBlue,
                                    decoration: TextDecoration.none));
                          },
                          itemCount: addresses.length,
                          physics: NeverScrollableScrollPhysics()))
                ])),
            rightButtonText: S.of(context).ok,
            leftButtonText: S.of(context).cancel,
            leftActionColor: Color(0xffFF6600),
            rightActionColor: Theme.of(context).accentTextTheme.body2.color,
            actionRightButton: () async {
              Navigator.of(context).pop();
              await ioniaPurchaseViewModel.commitPaymentInvoice();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }
}

class _IoniaTransactionCommitedAlert extends StatelessWidget {
  const _IoniaTransactionCommitedAlert({
    Key key,
    @required this.transactionInfo,
  }) : super(key: key);

  final AnyPayPaymentCommittedInfo transactionInfo;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.all(Radius.circular(30)),
      child: Container(
        width: 327,
        height: 340,
        color: Theme.of(context).accentTextTheme.title.decorationColor,
        child: Material(
          color: Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.fromLTRB(40, 20, 40, 0),
                child: Text(
                  S.of(context).awaiting_payment_confirmation,
                  textAlign: TextAlign.center,
                  style: textMediumSemiBold(
                    color: Theme.of(context).accentTextTheme.display4.backgroundColor,
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).transaction_sent,
                      style: textMedium(
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: 20),
                    Text(
                      S.of(context).transaction_sent_notice,
                      style: textMedium(
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.only(top: 16, bottom: 8),
                child: Container(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
              ),
              StandartListRow(
                title: '${S.current.transaction_details_transaction_id}:',
                value: transactionInfo.chain,
              ),
              StandartListRow(
                  title: '${S.current.view_in_block_explorer}:',
                  value: '${S.current.view_transaction_on} XMRChain.net'),
            ],
          ),
        ),
      ),
    );
  }
}

class TipButtonGroup extends StatelessWidget {
  const TipButtonGroup({
    Key key,
    @required this.selectedTip,
    @required this.onSelect,
    @required this.tipsList,
  }) : super(key: key);

  final Function(IoniaTip) onSelect;
  final double selectedTip;
  final List<IoniaTip> tipsList;

  bool _isSelected(double value) => selectedTip == value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...[
          for (var i = 0; i < tipsList.length; i++) ...[
            TipButton(
              isSelected: _isSelected(tipsList[i].percentage),
              onTap: () => onSelect(tipsList[i]),
              caption: '${tipsList[i].percentage}%',
              subTitle: '\$${tipsList[i].additionalAmount}',
            ),
            SizedBox(width: 4),
          ]
        ],
      ],
    );
  }
}

class TipButton extends StatelessWidget {
  const TipButton({
    @required this.caption,
    this.subTitle,
    @required this.onTap,
    this.isSelected = false,
  });

  final String caption;
  final String subTitle;
  final bool isSelected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 49,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(caption,
                style: textSmallSemiBold(
                    color: isSelected
                        ? Theme.of(context).accentTextTheme.title.color
                        : Theme.of(context).primaryTextTheme.title.color)),
            if (subTitle != null) ...[
              SizedBox(height: 4),
              Text(
                subTitle,
                style: textXxSmallSemiBold(
                  color: isSelected
                      ? Theme.of(context).accentTextTheme.title.color
                      : Theme.of(context).primaryTextTheme.overline.color,
                ),
              ),
            ]
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Color.fromRGBO(242, 240, 250, 1),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    Theme.of(context).primaryTextTheme.subhead.color,
                    Theme.of(context).primaryTextTheme.subhead.decorationColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
      ),
    );
  }
}
