import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/ionia/ionia_virtual_card.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_background.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class IoniaDebitCardPage extends BasePage {
  final IoniaViewModel _ioniaViewModel;

  IoniaDebitCardPage(this._ioniaViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.current.debit_card,
      style: TextStyle(
        fontSize: 22,
        fontFamily: 'Lato',
        fontWeight: FontWeight.w900,
      ),
    );
  }

  @override
  Widget body(BuildContext context) {
    return Observer(
      builder: (_) {
        final cardState = _ioniaViewModel.cardState;
        if (cardState is IoniaFetchingCard) {
          return Center(child: CircularProgressIndicator());
        }
        if (cardState is IoniaCardSuccess) {
          return ScrollableWithBottomSection(
            contentPadding: EdgeInsets.zero,
            content: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _IoniaDebitCard(
                    cardInfo: cardState.card,
                  )
                ],
              ),
            ),
            bottomSection: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20.0),
                  child: Text(
                    'If asked for a billing address, provide your shipping address',
                    style: textSmall(color: Theme.of(context).textTheme.display1.color),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 24),
                PrimaryButton(
                  text: 'Order Physical Card',
                  onPressed: () {},
                  color: Color(0xffE9F2FC),
                  textColor: Theme.of(context).textTheme.display2.color,
                ),
                SizedBox(height: 8),
                PrimaryButton(
                  text: 'Add Value',
                  onPressed: () {},
                  color: Theme.of(context).accentTextTheme.body2.color,
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
                          text: 'Get a',
                          style: textMedium(color: Theme.of(context).textTheme.display2.color),
                          children: [
                        TextSpan(
                          text: ' digital and physical prepaid debit card',
                          style: textMediumBold(color: Theme.of(context).textTheme.display2.color),
                        ),
                        TextSpan(
                            text: ' that you can reload with digital currencies. No additional information needed!')
                      ])),
                ),
              ],
            ),
          ),
          bottomSectionPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 32,
          ),
          bottomSection: PrimaryButton(
            text: 'Activate',
            onPressed: () => _showHowToUseCard(context, activate: true),
            color: Theme.of(context).accentTextTheme.body2.color,
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
                      color: Theme.of(context).backgroundColor,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'How to use this card',
                          style: textLargeSemiBold(
                            color: Theme.of(context).textTheme.body1.color,
                          ),
                        ),
                        SizedBox(height: 24),
                        Align(
                          alignment: Alignment.bottomLeft,
                          child: Text(
                            'Sign up for the card and accept the terms.',
                            style: textSmallSemiBold(
                              color: Theme.of(context).textTheme.display2.color,
                            ),
                          ),
                        ),
                        SizedBox(height: 24),
                        _TitleSubtitleTile(
                          title: 'Add prepaid funds to the cards (up to \$1000)',
                          subtitle:
                              'Funds are converted to USD when the held in the prepaid account, not in digital currencies.',
                        ),
                        SizedBox(height: 21),
                        _TitleSubtitleTile(
                          title: 'Use the digital card online or with contactless payment methods.',
                          subtitle: 'Optionally order a physical card.',
                        ),
                        SizedBox(height: 35),
                        PrimaryButton(
                          onPressed: () => activate
                              ? Navigator.pushNamed(context, Routes.ioniaActivateDebitCardPage)
                              : Navigator.pop(context),
                          text: 'Got it!',
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

class _IoniaDebitCard extends StatefulWidget {
  final bool isCardSample;
  final IoniaVirtualCard cardInfo;
  const _IoniaDebitCard({
    Key key,
    this.isCardSample = false,
    this.cardInfo,
  }) : super(key: key);

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

  @override
  Widget build(BuildContext context) {
    final last4 = widget.isCardSample ? '0000' : widget.cardInfo.pan.substring(widget.cardInfo.pan.length - 5);
    final spendLimit = widget.isCardSample ? '10000' : widget.cardInfo.spendLimit.toStringAsFixed(2);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 19),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
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
            widget.isCardSample ? 'up to \$$spendLimit' : '\$$spendLimit',
            style: textXLargeSemiBold(),
          ),
          SizedBox(height: 16),
          Text(
            _showDetails ? _formatPan(widget.cardInfo.pan) : '****  ****  ****  $last4',
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
                      _showDetails ? widget.cardInfo.cvv : '***',
                      style: textMediumSemiBold(),
                    )
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Expires',
                      style: textXSmallSemiBold(),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '${widget.cardInfo.expirationMonth ?? 'MM'}/${widget.cardInfo.expirationYear ?? 'YY'}',
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
                  _showDetails ? 'Hide Details' : 'Show Details',
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
  final String title;
  final String subtitle;
  const _TitleSubtitleTile({
    Key key,
    @required this.title,
    @required this.subtitle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textSmallSemiBold(color: Theme.of(context).textTheme.display2.color),
        ),
        SizedBox(height: 4),
        Text(
          subtitle,
          style: textSmall(color: Theme.of(context).textTheme.display2.color),
        ),
      ],
    );
  }
}
