import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/themes/extensions/receive_page_theme.dart';
import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/themes/extensions/cake_scrollbar_theme.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_gift_cards_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';

class IoniaDebitCardPage extends BasePage {
  final IoniaGiftCardsListViewModel _cardsListViewModel;

  IoniaDebitCardPage(this._cardsListViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.debit_card,
      style: textMediumSemiBold(
        color: Theme.of(context).extension<CakeTextTheme>()!.titleColor,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        final cardState = _cardsListViewModel.cardState;
        if (cardState is IoniaFetchingCard) {
          return Center(child: CircularProgressIndicator());
        }
        if (cardState is IoniaCardSuccess) {
          return ScrollableWithBottomSection(
            contentPadding: EdgeInsets.zero,
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _IoniaDebitCard(
                cardInfo: cardState.card,
              ),
            ),
            bottomSection: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    S.of(context).billing_address_info,
                    style: textSmall(
                        color: Theme.of(context).extension<ReceivePageTheme>()!.iconsColor),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
                PrimaryButton(
                  text: S.of(context).order_physical_card,
                  onPressed: () {},
                  color: Color(0xffE9F2FC),
                  textColor: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                ),
                SizedBox(height: 8),
                PrimaryButton(
                  text: S.of(context).add_value,
                  onPressed: () {},
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white,
                ),
                SizedBox(height: 16)
              ],
            ),
          );
        }
        return ScrollableWithBottomSection(
          contentPadding: EdgeInsets.zero,
          content: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                _IoniaDebitCard(isCardSample: true),
                SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Column(
                    children: [
                      TextIconButton(
                        label: S.current.how_to_use_card,
                        onTap: () => _showHowToUseCard(context),
                      ),
                      SizedBox(
                        height: 24,
                      ),
                      TextIconButton(
                        label: S.current.frequently_asked_questions,
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 50),
                Container(
                  padding: EdgeInsets.all(20),
                  margin: EdgeInsets.all(8),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(233, 242, 252, 1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: RichText(
                      text: TextSpan(
                    text: S.of(context).get_a,
                    style: textMedium(
                        color:
                            Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor),
                    children: [
                      TextSpan(
                        text: S.of(context).digital_and_physical_card,
                        style: textMediumBold(
                            color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor),
                      ),
                      TextSpan(
                        text: S.of(context).get_card_note,
                      )
                    ],
                  )),
                ),
              ],
            ),
          ),
          bottomSectionPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 32,
          ),
          bottomSection: PrimaryButton(
            text: S.of(context).activate,
            onPressed: () => _showHowToUseCard(context, activate: true),
            color: Theme.of(context).primaryColor,
            textColor: Colors.white,
          ),
        );
      },
    );
  }

  void _showHowToUseCard(BuildContext context, {bool activate = false}) {
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
                      color: Theme.of(context).colorScheme.background,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Text(
                          S.of(context).how_to_use_card,
                          style: textLargeSemiBold(
                            color:
                                Theme.of(context).extension<CakeScrollbarTheme>()!.thumbColor,
                          ),
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            S.of(context).signup_for_card_accept_terms,
                            style: textSmallSemiBold(
                              color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        _TitleSubtitleTile(
                          title: S.of(context).add_fund_to_card('1000'),
                          subtitle: S.of(context).use_card_info_two,
                        ),
                        SizedBox(height: 21),
                        _TitleSubtitleTile(
                          title: S.of(context).use_card_info_three,
                          subtitle: S.of(context).optionally_order_card,
                        ),
                        SizedBox(height: 35),
                        PrimaryButton(
                          onPressed: () => activate
                              ? Navigator.pushNamed(context, Routes.ioniaActivateDebitCardPage)
                              : Navigator.pop(context),
                          text: S.of(context).got_it,
                          color: Color.fromRGBO(233, 242, 252, 1),
                          textColor:
                              Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor,
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

class _IoniaDebitCard extends StatefulWidget {
  const _IoniaDebitCard({
    Key? key,
    this.cardInfo,
    this.isCardSample = false,
  }) : super(key: key);

  final bool isCardSample;
  final IoniaVirtualCard? cardInfo;

  @override
  _IoniaDebitCardState createState() => _IoniaDebitCardState();
}

class _IoniaDebitCardState extends State<_IoniaDebitCard> {
  bool _showDetails = false;
  void _toggleVisibility() {
    setState(() => _showDetails = !_showDetails);
  }

  String _formatPan(String pan) {
    if (pan == null) return '';
    return pan.replaceAllMapped(RegExp(r'.{4}'), (match) => '${match.group(0)}  ');
  }

  String get _getLast4 => widget.isCardSample ? '0000' : widget.cardInfo!.pan.substring(widget.cardInfo!.pan.length - 5);

  String get _getSpendLimit => widget.isCardSample ? '10000' : widget.cardInfo!.spendLimit.toStringAsFixed(2);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            Theme.of(context).extension<SendPageTheme>()!.firstGradientColor,
            Theme.of(context).extension<SendPageTheme>()!.secondGradientColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                S.current.cakepay_prepaid_card,
                style: textSmall(),
              ),
              Image.asset(
                'assets/images/mastercard.png',
                width: 54,
              ),
            ],
          ),
          Text(
            widget.isCardSample ? S.of(context).upto(_getSpendLimit) : '\$$_getSpendLimit',
            style: textXLargeSemiBold(),
          ),
          SizedBox(height: 16),
          Text(
            _showDetails ? _formatPan(widget.cardInfo?.pan ?? '') : '****  ****  ****  $_getLast4',
            style: textMediumSemiBold(),
          ),
          SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (widget.isCardSample)
                Text(
                  S.current.no_id_needed,
                  style: textMediumBold(),
                )
              else ...[
                Column(
                  children: [
                    Text(
                      'CVV',
                      style: textXSmallSemiBold(),
                    ),
                    SizedBox(height: 4),
                    Text(
                      _showDetails ? widget.cardInfo!.cvv : '***',
                      style: textMediumSemiBold(),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      S.of(context).expires,
                      style: textXSmallSemiBold(),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${widget.cardInfo?.expirationMonth ?? S.of(context).mm}/${widget.cardInfo?.expirationYear ?? S.of(context).yy}',
                      style: textMediumSemiBold(),
                    )
                  ],
                ),
              ]
            ],
          ),
          if (!widget.isCardSample) ...[
            SizedBox(height: 8),
            Center(
              child: InkWell(
                onTap: () => _toggleVisibility(),
                child: Text(
                  _showDetails ? S.of(context).hide_details : S.of(context).show_details,
                  style: textSmall(),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TitleSubtitleTile extends StatelessWidget {
  const _TitleSubtitleTile({
    Key? key,
    required this.title,
    required this.subtitle,
  }) : super(key: key);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textSmallSemiBold(
              color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: textSmall(
              color: Theme.of(context).extension<ReceivePageTheme>()!.tilesTextColor),
        ),
      ],
    );
  }
}
