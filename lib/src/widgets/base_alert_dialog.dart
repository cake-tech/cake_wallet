import 'dart:ui';

import 'package:cake_wallet/src/widgets/section_divider.dart';
import 'package:cake_wallet/utils/image_utill.dart';
import 'package:flutter/material.dart';

class BaseAlertDialog extends StatelessWidget {
  String? get headerText => '';

  String? get titleText => '';

  double? get titleTextSize => 20;

  String get contentText => '';

  Widget? get contentTextWidget => null;

  String get leftActionButtonText => '';

  String get rightActionButtonText => '';

  bool get isDividerExists => false;

  bool get isBottomDividerExists => true;

  VoidCallback get actionLeft => () {};

  VoidCallback get actionRight => () {};

  bool get barrierDismissible => true;

  Color? get leftActionButtonTextColor => null;

  Color? get rightActionButtonTextColor => null;

  Color? get leftActionButtonColor => null;

  Color? get rightActionButtonColor => null;

  String? get headerImageUrl => null;

  Key? leftActionButtonKey;

  Key? rightActionButtonKey;

  Key? dialogKey;

  Widget title(BuildContext context) {
    return Text(
      titleText!,
      textAlign: TextAlign.center,
      style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: titleTextSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
            decoration: TextDecoration.none,
          ),
    );
  }

  Widget headerTitle(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10.0),
      child: Text(
        headerText!,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.bodyMedium!.copyWith(
              fontSize: 25,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
              decoration: TextDecoration.none,
            ),
      ),
    );
  }

  Widget content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          contentTextWidget ??
              Text(
                contentText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 16,
                      decoration: TextDecoration.none,
                    ),
              ),
        ],
      ),
    );
  }

  Widget actionButtons(BuildContext context) {
    return Container(
      height: 60,
      child: Row(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: TextButton(
                key: leftActionButtonKey,
                onPressed: actionLeft,
                style: TextButton.styleFrom(
                  backgroundColor: leftActionButtonColor ?? Theme.of(context).colorScheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.zero),
                  ),
                ),
                child: Text(
                  leftActionButtonText,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: leftActionButtonTextColor ??
                            Theme.of(context).colorScheme.errorContainer,
                        decoration: TextDecoration.none,
                      ),
                )),
          ),
          const VerticalSectionDivider(),
          Expanded(
            child: TextButton(
              key: rightActionButtonKey,
              onPressed: actionRight,
              style: TextButton.styleFrom(
                backgroundColor: rightActionButtonColor ?? Theme.of(context).colorScheme.surface,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.zero),
                ),
              ),
              child: Text(
                rightActionButtonText,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium!.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: rightActionButtonTextColor ?? Theme.of(context).colorScheme.onSurface,
                      decoration: TextDecoration.none,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget headerImage(BuildContext context, String imageUrl) {
    return Positioned(
      top: -50,
      left: 0,
      right: 0,
      child: CircleAvatar(
        radius: 50,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: ClipOval(
          child: ImageUtil.getImageFromPath(imagePath: imageUrl, fit: BoxFit.cover),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: key,
      onTap: () => barrierDismissible ? Navigator.of(context).pop() : null,
      child: Container(
        color: Colors.transparent,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 3.0, sigmaY: 3.0),
          child: Container(
            decoration:
                BoxDecoration(color: Theme.of(context).colorScheme.surface.withOpacity(0.8)),
            child: Center(
              child: GestureDetector(
                onTap: () => null,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    color: Theme.of(context).colorScheme.surface,
                  ),
                  width: 300,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (headerImageUrl != null) headerImage(context, headerImageUrl!),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          if (headerImageUrl != null) const SizedBox(height: 50),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: <Widget>[
                              if (headerText?.isNotEmpty ?? false) headerTitle(context),
                              titleText != null
                                  ? Padding(
                                      padding: EdgeInsets.fromLTRB(24, 20, 24, 0),
                                      child: title(context),
                                    )
                                  : SizedBox(height: 16),
                              isDividerExists
                                  ? Padding(
                                      padding: EdgeInsets.only(top: 16, bottom: 8),
                                      child: const HorizontalSectionDivider(),
                                    )
                                  : Offstage(),
                              Padding(
                                padding: EdgeInsets.fromLTRB(24, 8, 24, 32),
                                child: content(context),
                              )
                            ],
                          ),
                          if (isBottomDividerExists) const HorizontalSectionDivider(),
                          ClipRRect(
                              borderRadius: BorderRadius.all(Radius.circular(30)),
                              child: actionButtons(context))
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
