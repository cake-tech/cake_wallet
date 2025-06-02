import 'dart:async';

import 'package:cake_wallet/entities/parsed_address.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/src/screens/contact/add_new_contact_page.dart';
import 'package:cake_wallet/src/screens/contact/new_contact_page.dart';
import 'package:cake_wallet/src/widgets/base_text_form_field.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/base_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/bottom_sheet/info_bottom_sheet_widget.dart';
import 'package:cake_wallet/src/widgets/primary_button.dart';
import 'package:cake_wallet/themes/core/material_base_theme.dart';
import 'package:cake_wallet/themes/utils/custom_theme_colors.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class AddContactBottomSheet extends InfoBottomSheet {
  AddContactBottomSheet({
    required String titleText,
    String? titleIconPath,
    required this.currentTheme,
    required FooterType footerType,
    this.contentImage,
    this.contentImageColor,
    this.content,
    required this.onHandlerSearch,
    String? singleActionButtonText,
    VoidCallback? onSingleActionButtonPressed,
    Key? singleActionButtonKey,
    String? doubleActionLeftButtonText,
    String? doubleActionRightButtonText,
    VoidCallback? onLeftActionButtonPressed,
    VoidCallback? onRightActionButtonPressed,
    Key? leftActionButtonKey,
    Key? rightActionButtonKey,
  })  : _onSingleActionButtonPressed = onSingleActionButtonPressed,
        _singleActionButtonText = singleActionButtonText,
        _singleActionButtonKey = singleActionButtonKey,
        super(
          titleText: titleText,
          titleIconPath: titleIconPath,
          currentTheme: currentTheme,
          footerType: footerType,
          contentImage: contentImage,
          contentImageColor: contentImageColor,
          content: content,
          singleActionButtonText: singleActionButtonText,
          onSingleActionButtonPressed: onSingleActionButtonPressed,
          singleActionButtonKey: singleActionButtonKey,
          doubleActionLeftButtonText: doubleActionLeftButtonText,
          doubleActionRightButtonText: doubleActionRightButtonText,
          onLeftActionButtonPressed: onLeftActionButtonPressed,
          onRightActionButtonPressed: onRightActionButtonPressed,
          leftActionButtonKey: leftActionButtonKey,
          rightActionButtonKey: rightActionButtonKey,
        );

  final MaterialThemeBase currentTheme;
  final String? contentImage;
  final Color? contentImageColor;
  final String? content;
  final String? _singleActionButtonText;
  final VoidCallback? _onSingleActionButtonPressed;
  final Key? _singleActionButtonKey;
  final Future<List<ParsedAddress>> Function(String query) onHandlerSearch;

  @override
  Widget? buildHeader(BuildContext context) => null;

  @override
  Widget contentWidget(BuildContext context) {
    final maxHeight = MediaQuery.of(context).size.height * 0.7;

    return SizedBox(
      height: maxHeight,
      child: Navigator(
        onPopPage: (route, result) => route.didPop(result),
        pages: [
          MaterialPage(
            child: NewContactPage(
              currentTheme: currentTheme,
              contentImage: contentImage,
              contentImageColor: contentImageColor,
              contentText: content,
              singleActionButtonText: _singleActionButtonText,
              onSingleActionButtonPressed: _onSingleActionButtonPressed,
              singleActionButtonKey: _singleActionButtonKey,
              onSearch: (query) async => await onHandlerSearch(query),
            ),
          ),
        ],
      ),
    );
  }
}