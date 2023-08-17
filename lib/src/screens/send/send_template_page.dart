import 'package:cake_wallet/themes/extensions/dashboard_page_theme.dart';
import 'package:cake_wallet/themes/extensions/keyboard_theme.dart';
import 'package:cake_wallet/themes/extensions/seed_widget_theme.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/src/widgets/trail_button.dart';
import 'package:cake_wallet/view_model/send/template_view_model.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/send/send_template_view_model.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/src/screens/send/widgets/prefix_currency_icon_widget.dart';
import 'package:cake_wallet/themes/extensions/send_page_theme.dart';
import 'package:cake_wallet/src/screens/send/widgets/send_template_card.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class SendTemplatePage extends BasePage {
  SendTemplatePage({required this.sendTemplateViewModel});

  final SendTemplateViewModel sendTemplateViewModel;
  final _formKey = GlobalKey<FormState>();
  final controller = PageController(initialPage: 0);

  @override
  String get title => S.current.exchange_new_template;

  @override
  bool get extendBodyBehindAppBar => true;

  @override
  bool get gradientAll => true;

  @override
  AppBarStyle get appBarStyle => AppBarStyle.transparent;

  @override
  Widget trailing(context) => Observer(builder: (_) {
        return sendTemplateViewModel.recipients.length > 1
            ? TrailButton(
                caption: S.of(context).remove,
                onPressed: () {
                  int pageToJump = (controller.page?.round() ?? 0) - 1;
                  pageToJump = pageToJump > 0 ? pageToJump : 0;
                  final recipient = _defineCurrentRecipient();
                  sendTemplateViewModel.removeRecipient(recipient);
                  controller.jumpToPage(pageToJump);
                })
            : TrailButton(
                caption: S.of(context).clear,
                onPressed: () {
                  final recipient = _defineCurrentRecipient();
                  _formKey.currentState?.reset();
                  recipient.reset();
                });
      });

  @override
  Widget body(BuildContext context) {
    return Form(
        key: _formKey,
        child: ScrollableWithBottomSection(
            contentPadding: EdgeInsets.only(bottom: 24),
            content: FocusTraversalGroup(
                policy: OrderedTraversalPolicy(),
                child: Column(children: [
                  Container(
                      height: 460,
                      child: Observer(builder: (_) {
                        return PageView.builder(
                            scrollDirection: Axis.horizontal,
                            controller: controller,
                            itemCount: sendTemplateViewModel.recipients.length,
                            itemBuilder: (_, index) {
                              final template = sendTemplateViewModel.recipients[index];
                              return SendTemplateCard(
                                  template: template,
                                  index: index,
                                  sendTemplateViewModel: sendTemplateViewModel);
                            });
                      })),
                  Padding(
                    padding: EdgeInsets.only(top: 10, left: 24, right: 24, bottom: 10),
                    child: Container(
                      height: 10,
                      child: Observer(
                        builder: (_) {
                          final count = sendTemplateViewModel.recipients.length;

                          return count > 1
                              ? SmoothPageIndicator(
                                  controller: controller,
                                  count: count,
                                  effect: ScrollingDotsEffect(
                                      spacing: 6.0,
                                      radius: 6.0,
                                      dotWidth: 6.0,
                                      dotHeight: 6.0,
                                      dotColor: Theme.of(context).extension<SendPageTheme>()!.indicatorDotColor,
                                      activeDotColor: Theme.of(context).extension<DashboardPageTheme>()!.indicatorDotTheme.activeIndicatorColor))
                              : Offstage();
                        },
                      ),
                    ),
                  ),
                ])),
            bottomSectionPadding: EdgeInsets.only(left: 24, right: 24, bottom: 24),
            bottomSection: Column(children: [
              if (sendTemplateViewModel.hasMultiRecipient)
                Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: PrimaryButton(
                        onPressed: () {
                          sendTemplateViewModel.addRecipient();
                          Future.delayed(const Duration(milliseconds: 250), () {
                            controller.jumpToPage(sendTemplateViewModel.recipients.length - 1);
                          });
                        },
                        text: S.of(context).add_receiver,
                        color: Colors.transparent,
                        textColor: Theme.of(context).extension<SeedWidgetTheme>()!.hintTextColor,
                        isDottedBorder: true,
                        borderColor:
                            Theme.of(context).extension<SendPageTheme>()!.templateBackgroundColor)),
              PrimaryButton(
                  onPressed: () {
                    if (_formKey.currentState != null && _formKey.currentState!.validate()) {
                      final mainTemplate = sendTemplateViewModel.recipients[0];
                      final additionalRecipients = sendTemplateViewModel.recipients
                          .map((element) => element.toTemplate(
                              cryptoCurrency: element.selectedCurrency.title,
                              fiatCurrency: sendTemplateViewModel.fiatCurrency))
                          .toList();

                      sendTemplateViewModel.addTemplate(
                          isCurrencySelected: mainTemplate.isCurrencySelected,
                          name: mainTemplate.name,
                          address: mainTemplate.address,
                          cryptoCurrency: mainTemplate.selectedCurrency.title,
                          amount: mainTemplate.output.cryptoAmount,
                          amountFiat: mainTemplate.output.fiatAmount,
                          additionalRecipients: additionalRecipients);
                      Navigator.of(context).pop();
                    }
                  },
                  text: S.of(context).save,
                  color: Theme.of(context).primaryColor,
                  textColor: Colors.white)
            ])));
  }

  TemplateViewModel _defineCurrentRecipient() {
    if (controller.page == null) {
      throw Exception('Controller page is null');
    }
    final itemCount = controller.page!.round();
    return sendTemplateViewModel.recipients[itemCount];
  }
}
