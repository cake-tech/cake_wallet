import 'package:cake_wallet/themes/extensions/cake_text_theme.dart';
import 'package:cake_wallet/ionia/ionia_create_state.dart';
import 'package:cake_wallet/routes.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/screens/ionia/widgets/text_icon_button.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';
import 'package:cake_wallet/typography.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cake_wallet/view_model/ionia/ionia_gift_cards_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:mobx/mobx.dart';

class IoniaActivateDebitCardPage extends BasePage {

  IoniaActivateDebitCardPage(this._cardsListViewModel);

  final IoniaGiftCardsListViewModel _cardsListViewModel;

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
    reaction((_) => _cardsListViewModel.createCardState, (IoniaCreateCardState state) {
      if (state is IoniaCreateCardFailure) {
        _onCreateCardFailure(context, state.error);
      }
      if (state is IoniaCreateCardSuccess) {
        _onCreateCardSuccess(context);
      }
    });
    return ScrollableWithBottomSection(
      contentPadding: EdgeInsets.zero,
      content: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            SizedBox(height: 16),
            Text(S.of(context).debit_card_terms),
            SizedBox(height: 24),
            Text(S.of(context).please_reference_document),
            SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Column(
                children: [
                  TextIconButton(
                    label: S.current.cardholder_agreement,
                    onTap: () {},
                  ),
                  SizedBox(
                    height: 24,
                  ),
                  TextIconButton(
                    label: S.current.e_sign_consent,
                    onTap: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomSection: LoadingPrimaryButton(
        onPressed: () {
          _cardsListViewModel.createCard();
        },
        isLoading: _cardsListViewModel.createCardState is IoniaCreateCardLoading,
        text: S.of(context).agree_and_continue,
        color: Theme.of(context).primaryColor,
        textColor: Colors.white,
      ),
    );
  }

  void _onCreateCardFailure(BuildContext context, String errorMessage) {
    showPopUp<void>(
        context: context,
        builder: (BuildContext context) {
          return AlertWithOneAction(
              alertTitle: S.current.error,
              alertContent: errorMessage,
              buttonText: S.of(context).ok,
              buttonAction: () => Navigator.of(context).pop());
        });
  }

  void _onCreateCardSuccess(BuildContext context) {
    Navigator.pushNamed(
      context,
      Routes.ioniaDebitCardPage,
    );
    showPopUp<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertWithOneAction(
          alertTitle: S.of(context).congratulations,
          alertContent: S.of(context).you_now_have_debit_card,
          buttonText: S.of(context).ok,
          buttonAction: () => Navigator.of(context).pop(),
        );
      },
    );
  }
}
