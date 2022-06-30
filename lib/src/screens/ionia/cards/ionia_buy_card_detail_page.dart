import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/ionia/ionia_merchant.dart';
import 'package:cake_wallet/palette.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/confirm_modal.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/discount_badge.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/themes/theme_base.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class IoniaBuyGiftCardDetailPage extends StatelessWidget {
  const IoniaBuyGiftCardDetailPage(this.amount, this.ioniaViewModel);

  final IoniaViewModel ioniaViewModel;

  final String amount;

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
      ioniaViewModel.selectedMerchant.legalName,
      style: textLargeSemiBold(color: Theme.of(context).accentTextTheme.display4.backgroundColor),
    );
  }

  @override
  Widget build(BuildContext context) {
    final merchant = ioniaViewModel.selectedMerchant;
    final _backgroundColor = currentTheme.type == ThemeType.dark ? backgroundDarkColor : backgroundLightColor;
    ioniaViewModel.onAmountChanged(amount);
    return Scaffold(
      backgroundColor: _backgroundColor,
      body: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.zero,
        content: Observer(builder: (_) {
          final tipAmount = ioniaViewModel.tipAmount;
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
                      '\$$amount',
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
                                '\$$amount',
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
                    SizedBox(height: 16),
                    Divider(),
                    SizedBox(height: 16),
                    Text(
                      S.of(context).you_pay,
                      style: textSmall(),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '22.3435345000 XMR',
                      style: textLargeSemiBold(),
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
                    TipButtonGroup(
                      selectedTip: tipAmount,
                      onSelect: (value) async {
                        if (value == 'custom') {
                         final tip = await Navigator.pushNamed(context, Routes.ioniaCustomTipPage, arguments: [amount]);
                           ioniaViewModel.addTip(tip as String);
                          return;
                        }
                        ioniaViewModel.addTip(value);
                      },
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
              child: PrimaryButton(
                onPressed: () => purchaseCard(context),
                text: S.of(context).purchase_gift_card,
                color: Theme.of(context).accentTextTheme.body2.color,
                textColor: Colors.white,
              ),
            ),
            SizedBox(height: 8),
            Text(S.of(context).settings_terms_and_conditions,
                style: textMediumSemiBold(
                  color: Theme.of(context).primaryTextTheme.body1.color,
                ).copyWith(fontSize: 12)),
            SizedBox(height: 16)
          ],
        ),
      ),
    );
  }

  void purchaseCard(BuildContext context) {
    showPopUp<void>(
      context: context,
      builder: (_) {
        return IoniaConfirmModal(
            alertTitle: S.of(context).confirm_sending,
            alertContent: SizedBox(
              //Todo:: substitute this widget with modal content
              height: 200,
            ),
            rightButtonText: S.of(context).ok,
            leftButtonText: S.of(context).cancel,
            leftActionColor: Color(0xffFF6600),
            rightActionColor: Theme.of(context).accentTextTheme.body2.color,
            actionRightButton: () async {
              Navigator.of(context).pop();
            },
            actionLeftButton: () => Navigator.of(context).pop());
      },
    );
  }

  void _showHowToUseCard(BuildContext context, IoniaMerchant merchant,) {
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
                            merchant.purchaseInstructions,
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
}

class TipButtonGroup extends StatelessWidget {
  const TipButtonGroup({
    Key key,
    @required this.selectedTip,
    @required this.onSelect,
  }) : super(key: key);

  final Function(String) onSelect;
  final double selectedTip;

  bool _isSelected(String value) {
    final tip = selectedTip.round().toString();

    if (value == 'custom' && !tipsList.contains(tip)) {
      return true;
    }

    return tip == value;
  }

  static const tipsList = ['0', '10', '20'];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ...[
          for (var i = 0; i < tipsList.length; i++) ...[
            TipButton(
              isSelected: _isSelected(tipsList[i]),
              onTap: () => onSelect(tipsList[i]),
              caption: '${tipsList[i]}%',
              subTitle: '\$0.00',
            ),
            SizedBox(width: 4),
          ]
        ],
        TipButton(
          isSelected: _isSelected('custom'),
          onTap: () => onSelect('custom'),
          caption: S.of(context).custom,
        ),
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
