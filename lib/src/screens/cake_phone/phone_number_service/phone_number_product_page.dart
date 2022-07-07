import 'package:cake_wallet/buy/buy_amount.dart';
import 'package:cake_wallet/buy/moonpay/moonpay_buy_provider.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/entities/cake_phone_entities/phone_number_service.dart';
import 'package:cake_wallet/entities/fiat_currency.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/cake_phone_settings_tile.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/plan_card.dart';
import 'package:cake_wallet/src/screens/cake_phone/widgets/receipt_row.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/src/widgets/info_alert_dialog.dart';
import 'package:cake_wallet/src/widgets/picker.dart';
import 'package:cake_wallet/store/app_store.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/cake_phone/phone_plan_view_model.dart';
import 'package:country_pickers/country.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:country_pickers/country_pickers.dart';
import 'package:country_pickers/countries.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class PhoneNumberProductPage extends BasePage {
  PhoneNumberProductPage(this.phonePlanViewModel, {this.phoneNumberService});

  final PhonePlanViewModel phonePlanViewModel;
  final PhoneNumberService phoneNumberService;

  @override
  Widget body(BuildContext context) => PhoneNumberProductBody(phonePlanViewModel, phoneNumberService);

  @override
  Widget middle(BuildContext context) {
    return Text(
      S.of(context).phone_number,
      style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          fontFamily: 'Lato',
          color: Theme.of(context).primaryTextTheme.title.decorationColor),
    );
  }
}

class PhoneNumberProductBody extends StatefulWidget {
  PhoneNumberProductBody(this.phonePlanViewModel, this.phoneNumberService);

  final PhonePlanViewModel phonePlanViewModel;
  final PhoneNumberService phoneNumberService;

  @override
  PhoneNumberProductBodyState createState() => PhoneNumberProductBodyState();
}

class PhoneNumberProductBodyState extends State<PhoneNumberProductBody> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: ScrollableWithBottomSection(
        contentPadding: EdgeInsets.symmetric(vertical: 20),
        content: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                "${widget.phoneNumberService != null ? S.of(context).additional : S.of(context).initial} " +
                    "${S.of(context).service_term}",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).primaryTextTheme.title.decorationColor,
                  fontFamily: 'Lato',
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24).copyWith(top: 8),
              child: Text(
                widget.phoneNumberService != null
                    ? S.of(context).phone_number_addition_promotion_text
                    : S.of(context).phone_number_promotion_text,
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
                    children: widget.phonePlanViewModel.servicePlans
                        .map((e) => PlanCard(
                              plan: e,
                              onTap: () {
                                if (widget.phonePlanViewModel.selectedPlan != e) {
                                  widget.phonePlanViewModel.selectedPlan = e;
                                }
                              },
                              isSelected: widget.phonePlanViewModel.selectedPlan == e,
                            ))
                        .toList(),
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
                  CakePhoneSettingsTile(
                    title: S.of(context).free_sms_email_forward,
                    value: Observer(builder: (_) {
                      return Text(
                        "${widget.phonePlanViewModel.selectedPlan.quantity}, " +
                            "${S.of(context).then} " +
                            "\$${(widget.phonePlanViewModel.rateInCents / 100).toStringAsFixed(2)} " +
                            "${S.of(context).per_message}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryTextTheme.title.color,
                        ),
                      );
                    }),
                  ),
                  if (widget.phoneNumberService != null)
                    CakePhoneSettingsTile(
                      title: S.of(context).phone_number,
                      value: Text(
                        widget.phoneNumberService.phoneNumber,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).primaryTextTheme.title.color,
                        ),
                      ),
                    ),
                  if (widget.phoneNumberService == null)
                    CakePhoneSettingsTile(
                      title: S.of(context).phone_number_country,
                      value: Observer(builder: (_) {
                        return Row(
                          children: [
                            Image.asset(
                              CountryPickerUtils.getFlagImageAssetPath(
                                  widget.phonePlanViewModel.selectedCountry.isoCode),
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
                                        widget.phonePlanViewModel.selectedCountry.name,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: Theme.of(context).primaryTextTheme.title.color,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    "(+${widget.phonePlanViewModel.selectedCountry.phoneCode})",
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
                      onTap: () {
                        showPopUp<void>(
                          context: context,
                          builder: (_) => Picker(
                            items: countryList,
                            displayItem: (dynamic country) {
                              final Country _country = country as Country;
                              return "${_country.name} (+${_country.phoneCode})";
                            },
                            selectedAtIndex: countryList.indexOf(widget.phonePlanViewModel.selectedCountry),
                            mainAxisAlignment: MainAxisAlignment.start,
                            onItemSelected: (Country country) {
                              widget.phonePlanViewModel.selectedCountry = country;
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
                    ),
                  const SizedBox(height: 25),
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
                              onTap: () => widget.phonePlanViewModel.removeAdditionalSms(),
                              child: quantityIcon(Icons.remove),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Observer(builder: (_) {
                                return Text(
                                  widget.phonePlanViewModel.additionalSms.toString(),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Theme.of(context).primaryTextTheme.title.color,
                                  ),
                                );
                              }),
                            ),
                            GestureDetector(
                              onTap: () => widget.phonePlanViewModel.addAdditionalSms(),
                              child: quantityIcon(Icons.add),
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
                    TextSpan(text: "${S.of(context).due_today}: "),
                    TextSpan(
                      text: "\$${widget.phonePlanViewModel.totalPrice}",
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
                          alertTitleColor: Theme.of(context).primaryTextTheme.title.decorationColor,
                          alertContent: S.of(context).confirm_delete_template,
                          contentWidget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReceiptRow(
                                  title: S.of(context).amount, value: amountText(widget.phonePlanViewModel.totalPrice)),
                              ReceiptRow(title: "${S.of(context).cake_pay_balance}: ", value: amountText(100)),
                            ],
                          ),
                          isDividerExists: true,
                          rightButtonText: S.of(context).ok,
                          leftButtonText: S.of(context).cancel,
                          rightActionButtonColor: Theme.of(context).accentTextTheme.body2.color,
                          leftActionButtonColor: Theme.of(context).primaryTextTheme.body2.backgroundColor,
                          actionRightButton: () {
                            Navigator.of(dialogContext).pop();
                            Navigator.pushNamedAndRemoveUntil(
                              context,
                              Routes.cakePhoneActiveServices,
                              ModalRoute.withName(Routes.cakePhoneWelcome),
                            );
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
                          alertTitle: S.of(context).confirm_sending,
                          alertTitleColor: Theme.of(context).primaryTextTheme.title.decorationColor,
                          alertContent: S.of(context).confirm_delete_template,
                          contentWidget: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ReceiptRow(
                                title: S.of(context).amount,
                                value: cryptoAmount(widget.phonePlanViewModel.totalPrice),
                              ),
                              ReceiptRow(
                                title: S.of(context).send_fee,
                                value: cryptoAmount(getIt
                                    .get<AppStore>()
                                    .wallet
                                    .calculateEstimatedFee(
                                      getIt.get<AppStore>().settingsStore.priority[getIt.get<AppStore>().wallet.type],
                                      widget.phonePlanViewModel.totalPrice.floor(),
                                    )
                                    .toDouble()),
                              ),
                              const SizedBox(height: 45),
                              Text(
                                S.of(context).recipient_address,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).primaryTextTheme.title.color,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                //TODO: remove static address if it will be generated everytime
                                "4B6c5ApfayzRN8jYxXyprv9me1vttSjF21WAz4HQ8JvS13RgRbgfQg7PPgvm2QMA8N1ed7izqPFsnCKGWWwFoGyjTFstzXm",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: Theme.of(context).accentTextTheme.subhead.color,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                          isDividerExists: true,
                          rightButtonText: S.of(context).ok,
                          leftButtonText: S.of(context).cancel,
                          rightActionButtonColor: Theme.of(context).accentTextTheme.body2.color,
                          leftActionButtonColor: Theme.of(context).primaryTextTheme.body2.backgroundColor,
                          actionRightButton: () {
                            Navigator.of(dialogContext).pop();
                            showPaymentConfirmationPopup();
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

  Widget quantityIcon(IconData icon) {
    if (widget.phoneNumberService == null) {
      return Container(
        padding: const EdgeInsets.all(8),
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Theme.of(context).accentTextTheme.body2.color,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 15),
      );
    }
    return Container(
      margin: const EdgeInsets.all(4),
      child: DottedBorder(
        borderType: BorderType.Circle,
        dashPattern: [3, 3],
        color: Theme.of(context).primaryTextTheme.display3.color,
        strokeWidth: 3,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Icon(
            icon,
            color: Theme.of(context).primaryTextTheme.display3.color,
            size: 15,
          ),
        ),
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

        if (snapshot.hasData) {
          sourceAmount = snapshot.data.sourceAmount;
          destAmount = snapshot.data.destAmount;
        } else {
          sourceAmount = 0.0;
          destAmount = 0.0;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              "${sourceAmount} ${getIt.get<AppStore>().wallet.currency.toString()}",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).primaryTextTheme.title.color,
              ),
            ),
            Text(
              "${destAmount} ${FiatCurrency.usd.title}",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).accentTextTheme.subhead.color,
              ),
            ),
          ],
        );
      },
    );
  }

  void showPaymentConfirmationPopup() {
    showPopUp<void>(
        context: context,
        builder: (dialogContext) {
          return InfoAlertDialog(
            alertTitle: S.of(context).awaiting_payment_confirmation,
            alertTitleColor: Theme.of(context).primaryTextTheme.title.decorationColor,
            alertContentPadding: EdgeInsets.zero,
            alertContent: Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 32),
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      S.of(context).transaction_sent_popup_info,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).primaryTextTheme.title.color,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Container(
                      height: 1,
                      color: Theme.of(context).dividerColor,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${S.of(context).transaction_details_transaction_id}:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).accentTextTheme.subhead.color,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4, bottom: 16),
                          child: Text(
                            // TODO: Replace with the transaction id
                            "dsyf5ind7akwryewkmf5nf4eakdrm4infd4i8rm4fd8nrmsein",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryTextTheme.title.color,
                            ),
                          ),
                        ),
                        Text(
                          "${S.of(context).view_in_block_explorer}:",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Theme.of(context).accentTextTheme.subhead.color,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            // TODO: get it from transaction details view model
                            S.of(context).view_transaction_on,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).primaryTextTheme.title.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
  }
}
