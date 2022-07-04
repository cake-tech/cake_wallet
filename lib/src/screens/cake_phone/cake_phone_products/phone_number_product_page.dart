import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/buy/buy_view_model.dart';
import 'package:cake_wallet/view_model/cake_phone/phone_plan_view_model.dart';
import 'package:country_pickers/country.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/countries.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/entities/service_plan.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PhoneNumberProductPage extends BasePage {
  PhoneNumberProductPage(this.phonePlanViewModel);

  final PhonePlanViewModel phonePlanViewModel;

  @override
  Widget body(BuildContext context) => PhoneNumberProductBody(phonePlanViewModel);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).phone_number,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.color),
    );
  }
}

class PhoneNumberProductBody extends StatefulWidget {
  PhoneNumberProductBody(this.phonePlanViewModel);

  final PhonePlanViewModel phonePlanViewModel;

  @override
  PhoneNumberProductBodyState createState() => PhoneNumberProductBodyState(phonePlanViewModel);
}

class PhoneNumberProductBodyState extends State<PhoneNumberProductBody> {
  PhoneNumberProductBodyState(this.phonePlanViewModel);

  final PhonePlanViewModel phonePlanViewModel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.symmetric(vertical: 20),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                S.of(context).initial_service_term,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryTextTheme.title.color,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 8),
              child: Text(
                S.of(context).phone_number_promotion_text,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).accentTextTheme.subhead.color,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            Observer(builder: (_) {
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: phonePlanViewModel.servicePlans.map((e) => planCard(e)).toList(),
                  ),
                ),
              );
            }),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).free_sms_email_forward,
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.subhead.color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).accentTextTheme.title.backgroundColor,
                        ),
                      ),
                    ),
                    child: Observer(builder: (_) {
                      return Text(
                        "${phonePlanViewModel.selectedPlan.quantity}, " +
                            "${S.of(context).then} " +
                            "\$${(phonePlanViewModel.rateInCents / 100).toStringAsFixed(2)} " +
                            "${S.of(context).per_message}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryTextTheme.title.color,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    S.of(context).phone_number_country,
                    style: TextStyle(
                      color: Theme.of(context).accentTextTheme.subhead.color,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.only(top: 8, bottom: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).accentTextTheme.title.backgroundColor,
                        ),
                      ),
                    ),
                    child: InkWell(
                      onTap: () {
                        showPopUp<void>(
                          context: context,
                          builder: (_) => Picker(
                            items: countryList,
                            displayItem: (dynamic country) {
                              final Country _country = country as Country;
                              return "${_country.name} (+${_country.phoneCode})";
                            },
                            selectedAtIndex: countryList.indexOf(phonePlanViewModel.selectedCountry),
                            mainAxisAlignment: MainAxisAlignment.start,
                            onItemSelected: (Country country) {
                              phonePlanViewModel.selectedCountry = country;
                            },
                            images: countryList
                                .map((e) => Image.asset(
                                      CountryPickerUtils.getFlagImageAssetPath(e.isoCode),
                                      height: 20.0,
                                      width: 36.0,
                                      fit: BoxFit.fill,
                                      package: "country_pickers",
                                    ))
                                .toList(),
                            isSeparated: false,
                            hintText: S.of(context).search_country,
                            matchingCriteria: (dynamic country, String searchText) {
                              final Country _country = country as Country;
                              searchText = searchText.toLowerCase();
                              return _country.name.toLowerCase().contains(searchText) ||
                                  _country.phoneCode.contains(searchText) ||
                                  _country.isoCode.toLowerCase().contains(searchText) ||
                                  _country.iso3Code.toLowerCase().contains(searchText);
                            },
                          ),
                        );
                      },
                      child: Observer(builder: (_) {
                        return Row(
                          children: [
                            Image.asset(
                              CountryPickerUtils.getFlagImageAssetPath(phonePlanViewModel.selectedCountry.isoCode),
                              height: 20.0,
                              width: 36.0,
                              fit: BoxFit.fill,
                              package: "country_pickers",
                            ),
                            Expanded(
                              child: Row(
                                children: [
                                  Flexible(
                                    child: Padding(
                                      padding: const EdgeInsets.only(left: 8, right: 6),
                                      child: Text(
                                        phonePlanViewModel.selectedCountry.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).primaryTextTheme.title.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "(+${phonePlanViewModel.selectedCountry.phoneCode})",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w400,
                                      color: Theme.of(context).primaryTextTheme.title.color,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              color: Theme.of(context).primaryTextTheme.title.color,
                              size: 16,
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 49),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        S.of(context).additional_sms_messages,
                        style: TextStyle(
                          color: Theme.of(context).accentTextTheme.subhead.color,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          color: Theme.of(context).primaryTextTheme.display3.decorationColor,
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: () => phonePlanViewModel.removeAdditionalSms(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).accentTextTheme.body2.color,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.remove, color: Colors.white, size: 15),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Observer(builder: (_) {
                                return Text(
                                  phonePlanViewModel.additionalSms.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryTextTheme.title.color,
                                  ),
                                );
                              }),
                            ),
                            GestureDetector(
                              onTap: () => phonePlanViewModel.addAdditionalSms(),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                margin: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).accentTextTheme.body2.color,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(Icons.add, color: Colors.white, size: 15),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomSectionPadding: EdgeInsets.only(bottom: 24, right: 24, left: 24),
        bottomSection: Column(
          children: <Widget>[
            Observer(builder: (_) {
              return RichText(
                text: TextSpan(
                  children: [
                    TextSpan(text: "${S.of(context).due_today} "),
                    TextSpan(
                      text: "\$${phonePlanViewModel.totalPrice}",
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ],
                  style: TextStyle(
                    fontSize: 15,
                    color: Theme.of(context).accentTextTheme.subhead.color,
                    fontFamily: 'Lato',
                  ),
                ),
              );
            }),
            const SizedBox(height: 24),
            PrimaryButton(
              onPressed: () {
                showPopUp<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertWithTwoActions(
                          alertTitle: S.of(context).confirm_payment,
                          alertContent: S.of(context).confirm_delete_template,
                          contentWidget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              receiptRow(S.of(context).amount, amountText(phonePlanViewModel.totalPrice)),
                              receiptRow(S.of(context).cake_pay_balance, amountText(100)),
                            ],
                          ),
                          isDividerExists: true,
                          rightButtonText: S.of(context).ok,
                          leftButtonText: S.of(context).cancel,
                          actionRightButton: () {
                            Navigator.of(dialogContext).pop();
                          },
                          actionLeftButton: () => Navigator.of(dialogContext).pop());
                    });
              },
              text: "${S.of(context).pay_with} ${S.of(context).cake_pay_balance}",
              color: Theme.of(context).accentTextTheme.caption.backgroundColor,
              textColor: Theme.of(context).primaryTextTheme.title.color,
            ),
            const SizedBox(height: 8),
            PrimaryButton(
              onPressed: () {
                showPopUp<void>(
                    context: context,
                    builder: (dialogContext) {
                      return AlertWithTwoActions(
                          alertTitle: S.of(context).confirm_payment,
                          alertContent: S.of(context).confirm_delete_template,
                          contentWidget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              receiptRow(S.of(context).amount, cryptoAmount(phonePlanViewModel.totalPrice)),
                              receiptRow(
                                  S.of(context).send_fee,
                                  cryptoAmount(getIt
                                      .get<AppStore>()
                                      .wallet
                                      .calculateEstimatedFee(
                                        getIt.get<AppStore>().settingsStore.priority[getIt.get<AppStore>().wallet.type],
                                        phonePlanViewModel.totalPrice.floor(),
                                      )
                                      .toDouble())),
                            ],
                          ),
                          isDividerExists: true,
                          rightButtonText: S.of(context).ok,
                          leftButtonText: S.of(context).cancel,
                          actionRightButton: () {
                            Navigator.of(dialogContext).pop();
                          },
                          actionLeftButton: () => Navigator.of(dialogContext).pop());
                    });
              },
              text: "${S.of(context).pay_with} ${getIt.get<AppStore>().wallet.currency.toString()}",
              color: Theme.of(context).accentTextTheme.body2.color,
              textColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget planCard(ServicePlan e) {
    final isSelected = phonePlanViewModel.selectedPlan == e;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          phonePlanViewModel.selectedPlan = e;
        }
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
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
          color: isSelected ? null : Theme.of(context).primaryTextTheme.display3.decorationColor,
        ),
        child: Column(
          children: [
            Text(
              "\$${e.price}/${S.of(context).month}",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
            Text(
              "${e.duration} ${S.of(context).month}",
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isSelected ? Colors.white : Theme.of(context).accentTextTheme.subhead.color,
                fontFamily: 'Lato',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget receiptRow(String title, Widget value) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "$title:",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Theme.of(context).accentTextTheme.subhead.color,
            ),
          ),
          value,
        ],
      ),
    );
  }

  Widget amountText(double amount) {
    return Text(
      "\$${amount.roundToDouble() == amount ? amount.round() : amount}",
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).primaryTextTheme.title.color,
      ),
    );
  }

  Widget cryptoAmount(double totalPrice) {
    return FutureBuilder<BuyAmount>(
        future: MoonPayBuyProvider(wallet: getIt.get<AppStore>().wallet)
            .calculateAmount(totalPrice.toString(), FiatCurrency.usd.title),
        builder: (context, AsyncSnapshot<BuyAmount> snapshot) {
          double sourceAmount;
          double destAmount;
          double achAmount;
          int minAmount;

          if (snapshot.hasData) {
            sourceAmount = snapshot.data.sourceAmount;
            destAmount = snapshot.data.destAmount;
            minAmount = snapshot.data.minAmount;
            achAmount = snapshot.data.achSourceAmount;
          } else {
            sourceAmount = 0.0;
            destAmount = 0.0;
            minAmount = 0;
          }

          return Column(
            children: [
              Text(sourceAmount.toString()),
              Text(destAmount.toString()),
            ],
          );
        });
  }
}
