import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/nano/nano.dart';
import 'package:cake_wallet/src/widgets/address_text_field.dart';
import 'package:cake_wallet/src/widgets/alert_with_one_action.dart';
import 'package:cake_wallet/src/widgets/alert_with_two_actions.dart';
import 'package:cake_wallet/store/settings_store.dart';
import 'package:cake_wallet/utils/payment_request.dart';
import 'package:cake_wallet/utils/show_pop_up.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/wallet_base.dart';
import 'package:cw_core/n2_node.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/src/screens/base_page.dart';
import 'package:cake_wallet/src/widgets/scollable_with_bottom_section.dart';

class NanoChangeRepPage extends BasePage {
  NanoChangeRepPage({required SettingsStore settingsStore, required WalletBase wallet})
      : _wallet = wallet,
        _settingsStore = settingsStore,
        _addressController = TextEditingController(),
        _formKey = GlobalKey<FormState>() {}

  final TextEditingController _addressController;
  final WalletBase _wallet;
  final SettingsStore _settingsStore;

  final GlobalKey<FormState> _formKey;

  @override
  String get title => S.current.change_rep;

  N2Node getCurrentRepNode(List<N2Node> nodes) {
    final currentRepAccount = nano!.getRepresentative(_wallet);
    final currentNode = nodes.firstWhere(
      (node) => node.account == currentRepAccount,
      orElse: () => N2Node(
        account: currentRepAccount,
        score: 0,
        uptime: "???",
        weight: 0,
      ),
    );
    return currentNode;
  }

  @override
  Widget body(BuildContext context) {
    return Form(
      key: _formKey,
      child: FutureBuilder(
        future: nano!.getN2Reps(_wallet),
        builder: (context, snapshot) {
          final reps = snapshot.data ?? [];

          return Container(
            padding: EdgeInsets.only(left: 24, right: 24),
            child: ScrollableWithBottomSection(
              topSectionPadding: EdgeInsets.only(bottom: 24),
              topSection: Column(
                children: [
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: AddressTextField(
                          controller: _addressController,
                          onURIScanned: (uri) {
                            final paymentRequest = PaymentRequest.fromUri(uri);
                            _addressController.text = paymentRequest.address;
                          },
                          options: [
                            AddressTextFieldOption.paste,
                            AddressTextFieldOption.qrCode,
                          ],
                          buttonColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                          validator: AddressValidator(type: CryptoCurrency.nano),
                        ),
                      )
                    ],
                  ),
                  Column(
                    children: [
                      Container(
                        margin: EdgeInsets.only(top: 12),
                        child: Text(
                          S.current.nano_current_rep,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                      ),
                      _buildSingleRepresentative(
                        context,
                        getCurrentRepNode(reps),
                        isList: false,
                        divider: false,
                      ),
                      if (reps.isNotEmpty) ...[
                        Divider(height: 20),
                        Container(
                          margin: EdgeInsets.only(top: 12),
                          child: Text(
                            S.current.nano_pick_new_rep,
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Divider(height: 20),
                      ],
                    ],
                  ),
                ],
              ),
              contentPadding: EdgeInsets.only(bottom: 24),
              content: Container(
                child: reps.isNotEmpty
                    ? Column(
                        children: _getRepresentativeWidgets(context, reps),
                      )
                    : SizedBox(),
              ),
              bottomSectionPadding: EdgeInsets.only(bottom: 24),
              bottomSection: Observer(
                  builder: (_) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Flexible(
                              child: Container(
                            padding: EdgeInsets.only(right: 8.0),
                            child: LoadingPrimaryButton(
                              onPressed: () => _onSubmit(context),
                              text: S.of(context).change,
                              color: Theme.of(context).colorScheme.primary,
                              textColor: Theme.of(context).colorScheme.onPrimary,
                            ),
                          )),
                        ],
                      )),
            ),
          );
        },
      ),
    );
  }

  Future<void> _onSubmit(BuildContext context) async {
    if (_formKey.currentState != null && !_formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await showPopUp<bool>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithTwoActions(
                  alertTitle: S.of(context).change_rep,
                  alertContent: S.of(context).change_rep_message,
                  rightButtonText: S.of(context).change,
                  leftButtonText: S.of(context).cancel,
                  actionRightButton: () => Navigator.pop(context, true),
                  actionLeftButton: () => Navigator.pop(context, false));
            }) ??
        false;

    if (confirmed) {
      try {
        _settingsStore.defaultNanoRep = _addressController.text;

        await nano!.changeRep(_wallet, _addressController.text);

        // reset this flag whenever we successfully change reps:
        _settingsStore.shouldShowRepWarning = true;

        await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).successful,
                  alertContent: S.of(context).change_rep_successful,
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.pop(context));
            });
      } catch (e) {
        await showPopUp<void>(
            context: context,
            builder: (BuildContext context) {
              return AlertWithOneAction(
                  alertTitle: S.of(context).error,
                  alertContent: e.toString(),
                  buttonText: S.of(context).ok,
                  buttonAction: () => Navigator.pop(context));
            });
      }
    }
  }

  List<Widget> _getRepresentativeWidgets(BuildContext context, List<N2Node>? list) {
    if (list == null) {
      return [];
    }
    final List<Widget> ret = [];
    for (final N2Node node in list) {
      if (node.alias != null && node.alias!.trim().isNotEmpty) {
        bool divider = node != list.first;
        ret.add(_buildSingleRepresentative(context, node, divider: divider, isList: true));
      }
    }
    return ret;
  }

  Widget _buildSingleRepresentative(
    BuildContext context,
    N2Node rep, {
    bool isList = true,
    bool divider = false,
  }) {
    return Column(
      children: <Widget>[
        if (divider) Divider(height: 2),
        TextButton(
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
          ),
          onPressed: () async {
            if (!isList) {
              return;
            }
            _addressController.text = rep.account!;
          },
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Container(
                  margin: const EdgeInsetsDirectional.only(start: 24),
                  width: MediaQuery.of(context).size.width * 0.50,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        rep.alias ?? rep.account!,
                        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w700,
                              fontSize: rep.alias == null ? 14 : 18,
                            ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 7),
                        child: RichText(
                          text: TextSpan(
                            text: "${S.current.voting_weight}: ${rep.weight.toString()}%",
                            style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        child: RichText(
                          text: TextSpan(
                            text: '',
                            children: [
                              TextSpan(
                                text: "${S.current.uptime}: ",
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w700,
                                    ),
                              ),
                              TextSpan(
                                text: rep.uptime,
                                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      fontWeight: FontWeight.w900,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  margin: const EdgeInsetsDirectional.only(end: 24, start: 14),
                  child: Stack(
                    children: <Widget>[
                      Icon(
                        Icons.verified,
                        color: Theme.of(context).colorScheme.primary,
                        size: 50,
                      ),
                      Positioned.fill(
                        child: Container(
                          margin: EdgeInsets.all(13),
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      Container(
                        alignment: const AlignmentDirectional(-0.03, 0.03),
                        width: 50,
                        height: 50,
                        child: Text(
                          (rep.score).toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
