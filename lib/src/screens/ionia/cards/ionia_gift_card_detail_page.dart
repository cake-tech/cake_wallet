import 'package:cake_wallet/ionia/ionia_gift_card.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/ionia_tile.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:cake_wallet/generated/i18n.dart';

class IoniaGiftCardDetailPage extends BasePage {
  IoniaGiftCardDetailPage(this.merchant);

  final IoniaGiftCard merchant;

  @override
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

  @override
  Widget middle(BuildContext context) {
    return Text(
      merchant.legalName,
      style: textLargeSemiBold(color: Theme.of(context).accentTextTheme.display4.backgroundColor),
    );
  }

  @override
  Widget body(BuildContext context) {
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.all(24),
      content: Column(
        children: [
          if (merchant.barcodeUrl != null && merchant.barcodeUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 24,
              ),
              child: SizedBox(height: 96, width: double.infinity, child: Image.network(merchant.barcodeUrl)),
            ),
          SizedBox(height: 24),
          IoniaTile(
            title: S.of(context).gift_card_number,
            subTitle: merchant.cardNumber,
          ),
          Divider(height: 30),
          IoniaTile(
            title: S.of(context).pin_number,
            subTitle: merchant.cardPin ?? '',
          ),
          Divider(height: 30),
          IoniaTile(
            title: S.of(context).amount,
            subTitle: merchant.remainingAmount.toString() ?? '0',
          ),
          Divider(height: 50),
          TextIconButton(
            label: S.of(context).how_to_use_card,
            onTap: () => _showHowToUseCard(context, merchant),
          ),
        ],
      ),
      bottomSection: Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: LoadingPrimaryButton(
            isLoading: false,
            onPressed: () {},
            text: S.of(context).mark_as_redeemed,
            color: Theme.of(context).accentTextTheme.body2.color,
            textColor: Colors.white,
          )),
    );
  }

  void _showHowToUseCard(
    BuildContext context,
    IoniaGiftCard merchant,
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
                            '',
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
