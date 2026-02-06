import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class KeyboardHideOverlay extends StatelessWidget {
  const KeyboardHideOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [Positioned.fill(child: child), if (Platform.isIOS) KeyboardHideButton()],
    );
  }
}

class KeyboardHideButton extends StatefulWidget {
  const KeyboardHideButton({super.key});

  @override
  State<KeyboardHideButton> createState() => _KeyboardHideButtonState();
}

class _KeyboardHideButtonState extends State<KeyboardHideButton> {
  double _lastInset = 0;
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.viewInsetsOf(context).bottom;

    if (inset != _lastInset) {
      _lastInset = inset;
      _visible = false;

      if (inset > 0) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && MediaQuery.viewInsetsOf(context).bottom == inset) {
            setState(() => _visible = true);
          }
        });
      }
    }

    return Align(
      alignment: Alignment.bottomRight,
      child: Padding(
        padding: EdgeInsets.only(bottom: inset),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 18),
          child: AnimatedOpacity(
            opacity: _visible ? 1 : 0,
            duration: const Duration(milliseconds: 100),
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SvgPicture.asset(
                      "assets/new-ui/hide_keyboard.svg",
                      colorFilter: ColorFilter.mode(
                          Theme.of(context).colorScheme.onPrimary, BlendMode.srcIn),
                    ),
                  )),
            ),
          ),
        ),
      ),
    );
  }
}
