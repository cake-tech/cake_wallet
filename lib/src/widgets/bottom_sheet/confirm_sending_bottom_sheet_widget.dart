import 'package:cake_wallet/core/address_validator.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/widgets/rounded_icon_button.dart';
import 'package:cake_wallet/themes/core/theme_extension.dart';
import 'package:cake_wallet/utils/address_formatter.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:cake_wallet/view_model/cake_pay/cake_pay_buy_card_view_model.dart';
import 'package:cake_wallet/view_model/send/output.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:cw_core/pending_transaction.dart';
import 'package:cw_core/wallet_type.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'base_bottom_sheet_widget.dart';

class ConfirmSendingBottomSheet extends BaseBottomSheet {
  ConfirmSendingBottomSheet({
    required String titleText,
    required FooterType footerType,
    String? titleIconPath,
    String? slideActionButtonText,
    VoidCallback? onSlideActionComplete,
    bool isSlideActionEnabled = true,
    String? accessibleNavigationModeSlideActionButtonText,
    required this.currency,
    this.paymentId,
    this.paymentIdValue,
    this.expirationTime,
    required this.amount,
    required this.amountValue,
    required this.fiatAmountValue,
    required this.fee,
    required this.feeValue,
    required this.feeFiatAmount,
    required this.outputs,
    required this.walletType,
    this.change,
    this.explanation,
    this.isOpenCryptoPay = false,
    this.cakePayBuyCardViewModel,
    this.quantity,
    Key? key,
  })  : showScrollbar = outputs.length > 3,
        super(
            titleText: titleText,
            maxHeight: 900,
            titleIconPath: titleIconPath,
            footerType: footerType,
            slideActionButtonText: slideActionButtonText ?? 'Swipe to send',
            onSlideActionComplete: onSlideActionComplete,
            isSlideActionEnabled: isSlideActionEnabled,
            accessibleNavigationModeSlideActionButtonText:
                accessibleNavigationModeSlideActionButtonText,
            key: key);

  final CryptoCurrency currency;
  final String? paymentId;
  final String? paymentIdValue;
  final String? expirationTime;
  final String amount;
  final String amountValue;
  final String fiatAmountValue;
  final String fee;
  final String feeValue;
  final String feeFiatAmount;
  final List<Output> outputs;
  final WalletType walletType;
  final PendingChange? change;
  final bool isOpenCryptoPay;
  final CakePayBuyCardViewModel? cakePayBuyCardViewModel;
  final String? quantity;
  final String? explanation;

  final bool showScrollbar;
  final ScrollController scrollController = ScrollController();

  bool get showAddress => !outputs
      .any((e) => RegExp(AddressValidator.bolt11InvoiceMatcher).hasMatch(e.address.toLowerCase()));

  @override
  Widget contentWidget(BuildContext context) {
    final itemTitleTextStyle = Theme.of(context).textTheme.bodyMedium!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        );
    final itemSubTitleTextStyle = Theme.of(context).textTheme.bodySmall!.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          decoration: TextDecoration.none,
        );

    final tileBackgroundColor = context.currentTheme.isDark
        ? context.customColors.backgroundGradientColor.withAlpha(140)
        : context.customColors.cardGradientColorPrimary;

    Widget content = Padding(
      padding: EdgeInsets.fromLTRB(8, 0, showScrollbar ? 16 : 8, 8),
      child: Column(
        children: [
          if (paymentId != null && paymentIdValue != null && cakePayBuyCardViewModel != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Observer(
                  builder: (_) => AddressTile(
                        itemTitle: paymentId!,
                        itemTitleTextStyle: itemTitleTextStyle,
                        amountTextStyle: itemSubTitleTextStyle,
                        walletType: walletType,
                        amount: expirationTime != null
                            ? S.current.offer_expires_in +
                                ' ${cakePayBuyCardViewModel!.formattedRemainingTime}'
                            : null,
                        address: paymentIdValue!,
                        itemSubTitleTextStyle: itemSubTitleTextStyle,
                        tileBackgroundColor: tileBackgroundColor,
                        applyAddressFormatting: false,
                        copyButton: true,
                      )),
            ),
          if (explanation != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: StandardInfoTile(
                value: explanation!,
                itemTitleTextStyle: itemTitleTextStyle,
                tileBackgroundColor: tileBackgroundColor,
              ),
            ),
          StandardTile(
            itemTitle: amount,
            itemValue: '$amountValue ${currency.title}',
            itemTitleTextStyle: itemTitleTextStyle,
            itemSubTitle: fiatAmountValue,
            itemSubTitleTextStyle: itemSubTitleTextStyle,
            tileBackgroundColor: tileBackgroundColor,
          ),
          const SizedBox(height: 8),
          StandardTile(
            itemTitle: fee,
            itemValue: feeValue,
            itemTitleTextStyle: itemTitleTextStyle,
            itemSubTitle: feeFiatAmount,
            itemSubTitleTextStyle: itemSubTitleTextStyle,
            tileBackgroundColor: tileBackgroundColor,
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              if (showAddress)
                ListView.separated(
                  padding: const EdgeInsets.only(top: 0),
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: outputs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final isBatchSending = outputs.length > 1;
                    final item = outputs[index];
                    final contactName = item.parsedAddress.name;
                    final isCakePayName = contactName == 'Cake Pay';
                    final batchContactTitle =
                        '${index + 1}/${outputs.length} - ${contactName.isEmpty ? 'Address' : contactName}';
                    final _address = item.isParsedAddress ? item.extractedAddress : item.address;
                    final _amount = '${item.cryptoAmount.replaceAll(',', '.')} ${currency.title}';
                    return isBatchSending || (contactName.isNotEmpty && !isCakePayName)
                        ? ExpansionAddressTile(
                            contactType: isOpenCryptoPay ? 'Open CryptoPay' : S.of(context).contact,
                            name: isBatchSending ? batchContactTitle : contactName,
                            address: _address,
                            amount: _amount,
                            walletType: walletType,
                            isBatchSending: isBatchSending,
                            itemTitleTextStyle: itemTitleTextStyle,
                            itemSubTitleTextStyle: itemSubTitleTextStyle,
                            tileBackgroundColor: tileBackgroundColor,
                          )
                        : AddressTile(
                            itemTitle: isCakePayName
                                ? item.parsedAddress.profileName
                                : S.of(context).address,
                            imagePath: isCakePayName ? item.parsedAddress.profileImageUrl : null,
                            itemTitleTextStyle: itemTitleTextStyle,
                            walletType: walletType,
                            amount: isCakePayName ? item.fiatAmount : _amount,
                            address: _address,
                            itemSubTitle: isCakePayName ? quantity : null,
                            itemSubTitleTextStyle: itemSubTitleTextStyle,
                            tileBackgroundColor: tileBackgroundColor,
                          );
                  },
                ),
              if (change != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: ExpansionAddressTile(
                    contactType: 'Change',
                    name: S.of(context).send_change_to_you,
                    address: change!.address,
                    amount: '${change!.amount} ${currency.title}',
                    isBatchSending: true,
                    walletType: walletType,
                    itemTitleTextStyle: itemTitleTextStyle,
                    itemSubTitleTextStyle: itemSubTitleTextStyle,
                    tileBackgroundColor: tileBackgroundColor,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
        ],
      ),
    );

    if (showScrollbar) {
      return SizedBox(
        height: 380,
        child: Scrollbar(
          controller: scrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: scrollController,
            physics: const BouncingScrollPhysics(),
            child: content,
          ),
        ),
      );
    } else {
      return content;
    }
  }
}

class StandardTile extends StatelessWidget {
  const StandardTile({
    super.key,
    required this.itemTitle,
    required this.itemValue,
    required this.itemTitleTextStyle,
    this.itemSubTitle,
    required this.itemSubTitleTextStyle,
    required this.tileBackgroundColor,
  });

  final String itemTitle;
  final String itemValue;
  final TextStyle itemTitleTextStyle;
  final String? itemSubTitle;
  final TextStyle itemSubTitleTextStyle;
  final Color tileBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: itemTitle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: tileBackgroundColor,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(itemTitle, style: itemTitleTextStyle),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(itemValue, style: itemTitleTextStyle),
                itemSubTitle == null
                    ? Container()
                    : Text(itemSubTitle!, style: itemSubTitleTextStyle),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class StandardInfoTile extends StatelessWidget {
  const StandardInfoTile({
    super.key,
    required this.value,
    required this.itemTitleTextStyle,
    required this.tileBackgroundColor,
  });

  final String value;
  final TextStyle itemTitleTextStyle;
  final Color tileBackgroundColor;

  @override
  Widget build(BuildContext context) => Semantics(
        container: true,
        label: value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: tileBackgroundColor,
          ),
          width: double.infinity,
          child: Text(value, style: itemTitleTextStyle),
        ),
      );
}

class AddressTile extends StatelessWidget {
  const AddressTile(
      {super.key,
      required this.itemTitle,
      required this.itemTitleTextStyle,
      required this.address,
      required this.itemSubTitleTextStyle,
      required this.tileBackgroundColor,
      required this.walletType,
      this.amountTextStyle,
      this.applyAddressFormatting = true,
      this.imagePath,
      this.amount,
      this.itemSubTitle,
      this.copyButton = false});

  final String itemTitle;
  final TextStyle itemTitleTextStyle;
  final String? amount;
  final String address;
  final TextStyle itemSubTitleTextStyle;
  final TextStyle? amountTextStyle;
  final Color tileBackgroundColor;
  final WalletType walletType;
  final bool applyAddressFormatting;
  final String? imagePath;
  final String? itemSubTitle;
  final bool copyButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: tileBackgroundColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    if (imagePath != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: ImageUtil.getImageFromPath(
                              imagePath: imagePath!, height: 40, width: 40),
                        ),
                      ),
                    Flexible(
                      child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Text(
                            itemTitle,
                            style: itemTitleTextStyle,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            softWrap: false,
                          )),
                    ),
                  ],
                ),
              ),
              if (amount != null) Text(amount!, style: amountTextStyle ?? itemTitleTextStyle),
            ],
          ),
          address.isEmpty
              ? Container()
              : applyAddressFormatting
                  ? AddressFormatter.buildSegmentedAddress(
                      address: address,
                      walletType: walletType,
                      evenTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                            fontWeight: FontWeight.w600,
                            decoration: TextDecoration.none,
                          ))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(address,
                            style: copyButton
                                ? itemTitleTextStyle.copyWith(fontSize: 12)
                                : itemTitleTextStyle),
                        SizedBox(width: 8),
                        if (copyButton)
                          RoundedIconButton(
                            icon: Icons.copy_all_outlined,
                            onPressed: () async =>
                                await Clipboard.setData(ClipboardData(text: address)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                      ],
                    ),
          itemSubTitle == null
              ? Container()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(itemSubTitle!, style: itemSubTitleTextStyle),
                  ],
                ),
        ],
      ),
    );
  }
}

class ExpansionAddressTile extends StatelessWidget {
  const ExpansionAddressTile({
    super.key,
    required this.contactType,
    required this.name,
    required this.address,
    required this.amount,
    required this.isBatchSending,
    required this.itemTitleTextStyle,
    required this.itemSubTitleTextStyle,
    required this.tileBackgroundColor,
    required this.walletType,
  });

  final String contactType;
  final String name;
  final String address;
  final String amount;
  final bool isBatchSending;
  final TextStyle itemTitleTextStyle;
  final TextStyle itemSubTitleTextStyle;
  final Color tileBackgroundColor;
  final WalletType walletType;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: name,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(10)),
          color: tileBackgroundColor,
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14, vertical: isBatchSending ? 0 : 8),
            child: ExpansionTile(
              childrenPadding: isBatchSending ? const EdgeInsets.only(bottom: 8) : EdgeInsets.zero,
              tilePadding: EdgeInsets.zero,
              dense: true,
              iconColor: Theme.of(context).colorScheme.onSurfaceVariant,
              visualDensity: VisualDensity.compact,
              title: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      isBatchSending ? name : contactType,
                      style: itemTitleTextStyle,
                      softWrap: true,
                    ),
                  ),
                  Text(
                    isBatchSending ? amount : name,
                    style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.none,
                        ),
                  ),
                ],
              ),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: AddressFormatter.buildSegmentedAddress(
                        address: address,
                        walletType: walletType,
                        evenTextStyle: Theme.of(context).textTheme.bodySmall!.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
